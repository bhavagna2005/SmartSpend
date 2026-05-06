class ApiEndpoints {
  // If you host your Python/ML model on a server later:
  static const String baseUrl = "https://your-ml-api.herokuapp.com";
  
  // Prediction Endpoints
  static const String categorizeSms = "$baseUrl/predict_category";
  static const String spendPrediction = "$baseUrl/predict_monthly_spend";
}