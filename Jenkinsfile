// Pipeline de construcción de la app móvil NovaERP (Flutter).
// El APK es opcional (parámetro BUILD_APK) porque Gradle pide más memoria de la
// que tiene la t3.small; por defecto se valida análisis estático y pruebas.
pipeline {
  agent any

  parameters {
    booleanParam(name: 'BUILD_APK', defaultValue: false,
                 description: 'Generar también el APK (lento en t3.small)')
  }

  options {
    timestamps()
    timeout(time: 40, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  stages {
    stage('Build móvil') {
      agent {
        docker {
          image 'ghcr.io/cirruslabs/flutter:stable'
          // El SDK de Flutter dentro de la imagen pertenece a root.
          args '-u root'
          reuseNode true
        }
      }
      steps {
        sh '''
          git config --global --add safe.directory '*'
          flutter --version
          flutter pub get
        '''
        sh 'flutter analyze --no-fatal-infos --no-fatal-warnings'
        // Las pruebas con la etiqueta "backend" necesitan una API viva; se excluyen.
        sh 'flutter test --exclude-tags backend'
        script {
          if (params.BUILD_APK) {
            sh 'flutter build apk --debug --dart-define-from-file=config/dev.json'
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk', fingerprint: true
          }
        }
      }
      post {
        // Devuelve los archivos al usuario jenkins (UID 1000) para poder limpiarlos.
        always { sh 'chown -R 1000:1000 .' }
      }
    }
  }

  post {
    always { notificar(currentBuild.currentResult) }
    cleanup { cleanWs() }
  }
}

// ---------------------------------------------------------------------------
// Notificaciones: Slack siempre; Trello solo si el último commit trae
// "trello:XXXXXXXX" (el código corto de la tarjeta, el de trello.com/c/XXXXXXXX).
// Build exitosa -> comenta y mueve la tarjeta a Completado.
// Build fallida -> solo comenta en la tarjeta.
// Un fallo al notificar nunca cambia el resultado de la build.
// ---------------------------------------------------------------------------
def notificar(String resultado) {
  def ok = resultado == 'SUCCESS'
  def icono = ok ? '✅' : '❌'
  def texto = "${icono} *${env.JOB_NAME}* #${env.BUILD_NUMBER}: ${resultado}\n${env.BUILD_URL}"

  try {
    writeFile file: '.slack.json', text: groovy.json.JsonOutput.toJson([text: texto])
    withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
      sh 'curl -fsS -X POST -H "Content-type: application/json" --data @.slack.json "$SLACK_URL"'
    }
  } catch (e) {
    echo "Slack no notificado: ${e}"
  }

  def tarjeta = tarjetaTrello(sh(script: 'git log -1 --pretty=%B', returnStdout: true))
  if (!tarjeta) {
    echo 'El commit no trae trello:XXXXXXXX; no se toca Trello.'
    return
  }
  try {
    withEnv(["CARD=${tarjeta}", "COMENTARIO=${icono} Build ${resultado}: ${env.BUILD_URL}"]) {
      withCredentials([string(credentialsId: 'trello-key', variable: 'TKEY'),
                       string(credentialsId: 'trello-token', variable: 'TTOKEN'),
                       string(credentialsId: 'trello-lista-completado', variable: 'TLIST')]) {
        sh '''curl -fsS -X POST "https://api.trello.com/1/cards/$CARD/actions/comments" \
                --data-urlencode "key=$TKEY" --data-urlencode "token=$TTOKEN" \
                --data-urlencode "text=$COMENTARIO" > /dev/null'''
        if (ok) {
          sh '''curl -fsS -X PUT "https://api.trello.com/1/cards/$CARD" \
                  --data-urlencode "key=$TKEY" --data-urlencode "token=$TTOKEN" \
                  --data-urlencode "idList=$TLIST" > /dev/null'''
        }
      }
    }
  } catch (e) {
    echo "Trello no actualizado: ${e}"
  }
}

@NonCPS
def tarjetaTrello(String mensaje) {
  def m = mensaje =~ /trello:([A-Za-z0-9]{8})/
  return m.find() ? m.group(1) : null
}
