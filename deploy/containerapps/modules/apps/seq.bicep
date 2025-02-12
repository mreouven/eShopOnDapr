param location string
param containerAppsEnvironmentId string

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'seq'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'seq'
          image: 'datalust/seq:latest'
          env: [
            {
              name: 'ACCEPT_EULA'
              value: 'Y'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
    configuration: {
      activeResivionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
