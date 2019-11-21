properties([
  parameters([
    choice (
      name: 'action',
      choices: ['apply', 'plan', 'refresh', 'destroy'].join('\n'),
      description: 'Which terraform action to run'
    ),
    choice (
      name: 'environment',
      choices: ['devint1','qa1', 'uat', 'prod'].join('\n'),
      description: "Which environment to apply the changes to (LZ will be determined based on environment)"
    ),
    string(
      name: 'branch',
      description: 'Which branch of the devops repo to use',
      defaultValue: 'master'
    ),
    string(
      name: 'targets',
      description: 'A comma separated list of terraform --target options'
    )
  ])
])

env.account = resolveAccount("customerapps", environment)
env.region = 'virginia'

terraformPipeline {
  namespace = 'pnp/infra'
  terraform_version = '0.11.13'
}
