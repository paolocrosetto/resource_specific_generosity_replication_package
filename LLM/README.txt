## LLM classification of open-ended texts

## Resource-specific generosity (2026)

## WHAT WE DID

To gain insight into the motives behind subjects’ allocations decisions, we asked each subjects, over three distinct open-ended questions, to explain their allocations of money, of the other resource (food, time, pens) they were asked to allocate, and to explain the difference (if any) in allocation between money and the other resource.

Each of 437 subjects replied to the three questions – explaining their decisions with respect to money, the other resource, and the difference between the two.

We used an LLM to identify from the open-ended textual data the main motive of subjects when explaining their allocation choices, and provided the LLM with five potential motives:
    • SOCIAL NORM, when subjects cited injunctive norms (“it is fair to do so”);
    • DESIRABILITY, when subjects cited liking (or not) a resource;
    • SATIATION, when subjects cited already having enough of a resource;
    • PERISHABILITY, when subjects cited concerns with limited future usefulness of the resource;
    • FUNGIBILITY, when subjects refer to the many uses of a resource;
    • OTHER, for all other motives or non-discernible or unclear sentences.

In particular, we used OpenAI GPT-4o-mini, called over OpenAI API using a python script. The LLM classification was run in November 2025

# HOW TO REPRODUCE

The raw data containing the open-ended texts produced by subjects are contained in the /LLM folder, split over three files, one for each of three questions the subjects replied to (texts_money.csv, texts_nonmoney.csv, texts_diff.csv)

For each of one of these three files there is a dedicated python script that contains the exact prompt that was used to turn the LLM into a classifier routine.

To save tokens, we sent texts in batches, and collected batches of replies; we then parsed the replies to turn them into a clean dataset.

## PARAMETERS

To run the python scripts, you need to
- set YOUR OPENAI API in the os.environ["OPENAI_API_KEY"] line
- if you do not have an OpenAI API key, get one -- this script relies on tokens from the PAID version of OpenAI -- it uses very few tokens, as it ran on about 10 USD cents.
- check that you have the right path to the input texts and change, if needed the path to the output data.

You need to run each of three files once; then check if in the output "ERROR" is present. This can happen because the LLM fails to classify, or because of technical reasons (connection...) or because the parsing of the LLM output failed (missing commas, non-standard format in LLM response, etc). In this case, just isolate the texts for which an ERROR was produce, try to see what went wrong and rerun.
