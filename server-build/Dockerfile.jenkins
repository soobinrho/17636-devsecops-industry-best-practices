FROM jenkins/jenkins:lts-jdk25

# How to manage Jenkins plugins:
#   https://www.jenkins.io/blog/2023/06/20/remove-outdated-plugins-while-using-docker/
COPY --chown=jenkins:jenkins ./17636-jenkins-plugins.txt /usr/share/jenkins/plugins.txt
RUN jenkins-plugin-cli --plugin-file=/usr/share/jenkins/plugins.txt

# How to configure Jenkins Configuration as Code.
#   https://github.com/jenkinsci/configuration-as-code-plugin/
COPY --chown=jenkins:jenkins ./17636-jenkins-configuration-as-code.yaml /usr/share/jenkins/jenkins.yaml
