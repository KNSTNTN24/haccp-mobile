const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const RECIPE_PROMPT = `You are a professional chef and food safety specialist. Analyze the provided recipe content and extract a complete, structured recipe.

Pay attention to:
- All ingredients with quantities and units
- Cooking techniques and methods
- Temperatures and timings
- The dish name and category
- EU 14 allergens in each ingredient

Return a JSON object with this exact structure (no markdown, just pure JSON):
{
  "name": "Recipe Name",
  "description": "Brief 1-2 sentence description",
  "category": "main|starter|dessert|side|sauce|drink|other",
  "instructions": "Detailed step-by-step instructions, numbered",
  "cookingMethod": "e.g., Bake, Fry, Boil, Sauté",
  "cookingTemp": null or number in Celsius,
  "cookingTime": null or number,
  "cookingTimeUnit": "minutes|hours",
  "ingredients": [
    {
      "name": "Ingredient name",
      "quantity": "amount as string",
      "unit": "g|ml|tsp|tbsp|cup|piece|etc",
      "allergens": []
    }
  ]
}

For allergens, only use values from the EU 14 allergens list:
gluten, crustaceans, eggs, fish, peanuts, soybeans, milk, nuts, celery, mustard, sesame, sulphites, lupin, molluscs

Return ONLY valid JSON, no other text.`;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { text, pdf_base64, image_base64, image_mime, filename } = body;

    if (!text && !pdf_base64 && !image_base64) {
      return new Response(
        JSON.stringify({ error: "Please provide recipe text, a PDF, or a photo." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!anthropicKey) {
      console.log("ANTHROPIC_API_KEY not set — returning mock recipe");
      const mock = {
        name: "Pasta Aglio e Olio",
        description: "Classic Italian pasta with garlic and olive oil.",
        category: "main",
        instructions: "1. Cook spaghetti al dente.\n2. Heat olive oil, add sliced garlic and chili flakes.\n3. Toss pasta in garlic oil.\n4. Add parsley, salt, pepper.\n5. Serve with Parmesan.",
        cookingMethod: "Boil + sauté",
        cookingTemp: null,
        cookingTime: 20,
        cookingTimeUnit: "minutes",
        ingredients: [
          { name: "Spaghetti", quantity: "400", unit: "g", allergens: ["gluten"] },
          { name: "Garlic", quantity: "6", unit: "cloves", allergens: [] },
          { name: "Olive oil", quantity: "80", unit: "ml", allergens: [] },
          { name: "Red pepper flakes", quantity: "1", unit: "tsp", allergens: [] },
          { name: "Parsley", quantity: "1", unit: "bunch", allergens: [] },
          { name: "Parmesan cheese", quantity: "50", unit: "g", allergens: ["milk"] },
        ],
      };
      return new Response(JSON.stringify(mock), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Build content array
    const content: any[] = [];

    if (image_base64) {
      console.log(`Analyzing image: ${filename || "recipe.jpg"} (${image_mime || "image/jpeg"})`);
      content.push({
        type: "image",
        source: {
          type: "base64",
          media_type: image_mime || "image/jpeg",
          data: image_base64,
        },
      });
      content.push({
        type: "text",
        text: RECIPE_PROMPT,
      });
    } else if (pdf_base64) {
      console.log(`Analyzing PDF: ${filename || "recipe.pdf"}`);
      content.push({
        type: "document",
        source: {
          type: "base64",
          media_type: "application/pdf",
          data: pdf_base64,
        },
      });
      content.push({
        type: "text",
        text: RECIPE_PROMPT,
      });
    } else {
      console.log(`Analyzing text (${text.length} chars)`);
      content.push({
        type: "text",
        text: `Here is the recipe text to analyze:\n\n---\n${text}\n---\n\n${RECIPE_PROMPT}`,
      });
    }

    const claudeResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicKey,
          "anthropic-version": "2023-06-01",
          "anthropic-beta": "pdfs-2024-09-25",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 4096,
          messages: [
            {
              role: "user",
              content: content,
            },
          ],
        }),
      }
    );

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(`Claude API error: ${claudeResponse.status}`, errText);
      throw new Error(`Claude API error: ${claudeResponse.status} — ${errText.substring(0, 300)}`);
    }

    const claudeData = await claudeResponse.json();
    const responseText = claudeData.content?.[0]?.text ?? "";

    let recipe;
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        recipe = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("No JSON found in Claude response");
      }
    } catch (parseErr) {
      console.error("Parse error. Raw response:", responseText.substring(0, 500));
      throw new Error(`Failed to parse recipe from AI response`);
    }

    return new Response(JSON.stringify(recipe), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("import-recipe error:", err);
    return new Response(
      JSON.stringify({ error: err.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
