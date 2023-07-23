pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Define Docker Image name
                    def dockerImage = docker.build('npm-sample', '-f instDockerfile .')
                    def container = docker.run(dockerImage.id)
                    sh "docker cp ${container}:/usr/share/nginx/html/sbom.json ."
                }
            }
        }
        

        stage('Archive File') {
            steps {
                // Archive the file as a build artifact
                archiveArtifacts artifacts: 'sbom.json', fingerprint: true
            }
        }

    }
}
