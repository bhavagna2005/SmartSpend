pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Python') {
            steps {
                bat 'python --version'
            }
        }

        stage('Verify Dependencies') {
            steps {
                bat 'python -m pip install -r backend/requirements.txt'
            }
        }

        stage('Validate Backend Files') {
            steps {
                bat 'python -m py_compile backend/app.py'
                bat 'if not exist backend/logistic_model.pkl exit /b 1'
                bat 'if not exist backend/tfidf_vectorizer.pkl exit /b 1'
            }
        }
    }
}
