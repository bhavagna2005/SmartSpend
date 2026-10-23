
pipeline {
    agent any

    environment {
        PYTHON = 'C:\\Users\\Srinivas\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'
        DOCKER = 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Python') {
            steps {
                bat '"%PYTHON%" --version'
            }
        }

        stage('Verify Dependencies') {
            steps {
                bat '"%PYTHON%" -m pip install -r backend/requirements.txt'
            }
        }

        stage('Validate Backend Files') {
            steps {
                bat '"%PYTHON%" -m py_compile backend/app.py'
                bat 'if not exist backend\\logistic_model.pkl exit /b 1'
                bat 'if not exist backend\\tfidf_vectorizer.pkl exit /b 1'
            }
        }

        stage('Check Docker') {
            steps {
                bat '"%DOCKER%" --version'
                bat '"%DOCKER%" info'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '"%DOCKER%" build -t smartspend-backend:1.0 -f backend/Dockerfile .'
            }
        }
    }
}

