pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Define Docker Image name
                    def dockerImage = docker.build('npm-sample', '-f instDockerfile .')
                }
            }
        }
        stage('Extract File') {
            steps {
                script {
                    // Run the container
                    def container = docker.run(dockerImage.id)
                    // Copy the file from the container to the Jenkins workspace
                    sh "docker cp ${container.id}:/usr/share/nginx/html/sbom.json ."
                    // Remove the container
                    container.stop()
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
