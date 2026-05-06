from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib

app = Flask(__name__)
CORS(app) # This allows your phone to connect without being blocked

# 1. Load your Brain (the files from Colab)
model = joblib.load('logistic_model.pkl')
vectorizer = joblib.load('tfidf_vectorizer.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # 2. Receive the SMS text from the Flutter App
        data = request.json
        sms_text = data.get('text', '')
        print(f"📩 Received SMS for prediction: {sms_text}")

        # 3. Convert text to numbers and predict
        text_vectorized = vectorizer.transform([sms_text])
        prediction = model.predict(text_vectorized)[0]
        print(f"🤖 Prediction: {prediction}")

        # 4. Send the category back to the phone
        return jsonify({'category': str(prediction)})
    except Exception as e:
        print(f"❌ Error during prediction: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # '0.0.0.0' makes the server visible to your phone on the Wi-Fi
    app.run(host='0.0.0.0', port=5000, debug=True)