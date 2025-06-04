# --- app.py ---
from flask import Flask, render_template, request
from chatterbot import ChatBot
from chatterbot.trainers import ListTrainer
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# --- Load safety data ---
locations_df = pd.read_csv("safety_locations.csv")

def get_resources(city: str, resource_type: str = None) -> str:
    city_df = locations_df[locations_df['City'].str.lower() == city.lower()]
    if city_df.empty:
        return f"Sorry, I don’t have data for {city.title()}."

    if resource_type:
        type_df = city_df[city_df['Resource Type'].str.lower() == resource_type.lower()]
        if type_df.empty:
            return f"No {resource_type}s found for {city.title()}."
        return f"Here are some {resource_type}s in {city.title()}:\n" + "\n".join(type_df['Details'].tolist())
    else:
        grouped = city_df.groupby("Resource Type")['Details'].apply(list)
        return f"Resources in {city.title()}:\n\n" + "\n\n".join(
            f"{rtype}:\n" + "\n".join(details) for rtype, details in grouped.items()
        )

# --- Setup ChatBot ---
safety_bot = ChatBot(
    'SafetyBot',
    storage_adapter='chatterbot.storage.SQLStorageAdapter',
    database_uri='sqlite:///db.sqlite3',
    logic_adapters=[
        'chatterbot.logic.BestMatch',
        {
            'import_path': 'chatterbot.logic.SpecificResponseAdapter',
            'input_text': 'Emergency',
            'output_text': 'Please call 101 immediately. This chatbot cannot help in crisis situations.'
        }
    ]
)

# --- Emergency detection ---
EMERGENCY_KEYWORDS = {
    'emergency', 'help me', 'in danger', 'rape', 'attack', 'threat', 'unsafe',
    'assault', 'fire', 'medical emergency', 'accident', 'kidnap', 'call police'
}

def contains_emergency(text):
    lowered = text.lower()
    return any(keyword in lowered for keyword in EMERGENCY_KEYWORDS)

@app.route("/")
def home():
    return render_template("index.html", intro="Hi! This is not an emergency bot. Please call 101 in case of emergency.")

@app.route("/get")
def get_response():
    user_text = request.args.get('msg', "").strip()
    lowered = user_text.lower()

    if contains_emergency(lowered):
        return "EMERGENCY_REDIRECT: Please call 101 immediately."

    # Smart city/resource detection
    cities = locations_df['City'].dropna().str.lower().unique()
    types = locations_df['Resource Type'].dropna().str.lower().unique()

    found_city = next((c for c in cities if c in lowered), None)
    found_type = next((t for t in types if t in lowered), None)

    if found_city:
        return get_resources(found_city, found_type)

    response = safety_bot.get_response(user_text)
    return str(response)

if __name__ == "__main__":
    app.run(debug=True)
