import os
import pandas as pd
from openai import OpenAI
import math
import re
from tqdm import tqdm

# -------------------------
# Configuration
# -------------------------
INPUT_FILE = "texts_diff.csv"
OUTPUT_FILE = "classified_diff.csv"
INTERMEDIATE_FILE = "classified_partial.csv"
BATCH_SIZE = 20        # number of sentences per API call
MODEL = "gpt-4o-mini"  # select preferred model; this is the one we used

# -------------------------
# Initialize OpenAI client
# -------------------------
os.environ["OPENAI_API_KEY"] = "your_API_key_here"
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# -------------------------
# Load data
# -------------------------
df = pd.read_csv(INPUT_FILE, encoding="utf-8")
assert all(col in df.columns for col in ["ID", "explain_diff"]), "Missing required columns"

# Prepare classification column
if "classification_diff" not in df.columns:
    df["classification_diff"] = None

# -------------------------
# Classification function for a batch
# -------------------------
def classify_batch(texts):
    numbered_texts = "\n".join([f"{i+1}. {t}" for i, t in enumerate(texts)])
    prompt = f"""
You are going to read a series of statements made by participants to an economics study, and you will have to classify them into different categories. 

Participants had to hypothetically allocate between themselves and another (unknown) participant 10 units of different resources: money, and one out of time, oatmeals, bic pens.
Participants saw these instructions:
    
---------------
You will make a series of hypothetical choices today about how you would choose to allocate resources between yourself and another participant.
You are given 10 [1$ bills / ballpoint pens / minutes off crossing "e" out of a text / brown-sugar instant oatmeal packets]. 
You can distribute them however you want between you and the other person.
Please indicate how much you would keep to yourself.
--------------

After the choices, we asked the subjects three questions, 

1. [justification money] Please explain in at least 2-3 sentences why you allocated this proportion of money to the other participant (vs yourself)
2. [justification other resource] Please explain in at least 2-3 sentences why you allocated this proportion of [other resource] to the other participant (vs yourself)
3. [comparison] Please explain why you allocated LESS/SAME/MORE of one resource or the other to the other participant.


Your role si to read the THIRD question -- comparison and classify what you think is the MAIN reported motivations for the choice. 

Your answer will be one and only one of the following: SOCIALNORM, DESIRABILITY, FUNGIBILITY, PERISHABILITY, SATIATION, OTHER. 

- FUNGIBILITY means that the subject refers to the fact that some resources are more fungible than others either directly or indirectly (e.g. with X one can have many uses; X can be used to make more things....)
- DESIRABILITY means that the subject indicates liking a resource more as the main reason for the choice (e.g. directly saying that she likes more one resource, or less the other)
- SOCIALNORM means that the subject cites an injunctive norm of behavior as a justification for the choice (e.g. "it is fair to do so" or their choice is "how things should be")
- SATIATION means that the subject indicates already having enough of one resource and hence valuing the extra units less (e.g. "I already have at home so this is less valuable to me")
- PERISHABILITY means that the subject indicates that the resource qill go awry or be in other ways less useful in the future (e.g. 'no need in amassing the resource as it will go off')
- OTHER refers to all the replies that do not fall in the above categories, or for answers that do not cite any reason (e.g. "just because" or "I dislike my matched person so I did not give any" or "I am in a bad mood today")

For each row (that uniquely identifes a subject), row index 1 to N, read the three replies, make up your mind as to the best-fitting category. 

Then reply strictly using the scheme: 1: FUNGIBILITY; 2: SATIATION; 3. DESIRABILITY ...


{numbered_texts}
"""
    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": "You are a text classifier. Reply uniquely by SOCIALNORM, DESIRABILITY, FUNGIBILITY, PERISHABILITY, SATIATION, OTHER."},
                {"role": "user", "content": prompt},
            ],
            temperature=0
        )
        text_out = response.choices[0].message.content.strip()
        
        
        # Parse structured response with regex
        pattern = r"(\d+)\s*:\s*(SOCIALNORM|DESIRABILITY|FUNGIBILITY|PERISHABILITY|SATIATION|OTHER)"
        matches = re.findall(pattern, text_out, flags=re.IGNORECASE)

        classifications = ["ERROR"] * len(texts)
        for idx_str, label in matches:
            idx_i = int(idx_str)-1
            if 0 <= idx_i < len(texts):
                classifications[idx_i] = label.upper()
                
        return classifications
    except Exception as e:
        print(f"Error classifying batch: {e}")
        return ["ERROR"] * len(texts)


    
# -------------------------
# Run classification in batches with progress bar
# -------------------------
num_batches = math.ceil(len(df)/BATCH_SIZE)

for i in tqdm(range(num_batches), desc="Classifying batches"):
    start = i * BATCH_SIZE
    end = min((i+1) * BATCH_SIZE, len(df))
    
    batch_index = df.index[start:end]           # real index labels
    batch_texts = df["explain_diff"].iloc[start:end].tolist()
    
    batch_classes = classify_batch(batch_texts)
    
    # Ensure batch_classes matches the length of batch_texts
    if len(batch_classes) < len(batch_texts):
        batch_classes += ["ERROR"] * (len(batch_texts) - len(batch_classes))
    elif len(batch_classes) > len(batch_texts):
        batch_classes = batch_classes[:len(batch_texts)]
    
    # Assign classifications safely
    df.loc[batch_index, "classification_diff"] = batch_classes
    
    # Save intermediate results after each batch
    df.to_csv(INTERMEDIATE_FILE, index=False, encoding="utf-8")



# -------------------------
# Save final CSV
# -------------------------
df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8")

print(f"\n✅ Classification complete! Results saved to {OUTPUT_FILE}")
