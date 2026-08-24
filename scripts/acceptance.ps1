$ErrorActionPreference = "Stop"

function Invoke-Moon {
  & moon @args
  if ($LASTEXITCODE -ne 0) {
    throw "moon command failed: $args"
  }
}

Invoke-Moon fmt --check
Invoke-Moon check --target all
Invoke-Moon test

Invoke-Moon run cmd/main -- inspect fixtures/valid-single.mrc
Invoke-Moon run cmd/main -- validate fixtures/valid-single.mrc
Invoke-Moon run cmd/main -- show fixtures/valid-single.mrc --record 1
Invoke-Moon run cmd/main -- query fixtures/valid-single.mrc '245$a'
Invoke-Moon run cmd/main -- convert fixtures/valid-single.mrc --format json --pretty --output examples/acceptance.json
Invoke-Moon run cmd/main -- convert examples/acceptance.json --format mrc --output examples/acceptance-from-json.mrc
Invoke-Moon run cmd/main -- convert fixtures/valid-single.mrc --format marcxml --output examples/acceptance.xml
Invoke-Moon run cmd/main -- convert examples/acceptance.xml --format mrc --output examples/acceptance-from-xml.mrc
Invoke-Moon run cmd/main -- privacy fixtures/valid-single.mrc
Invoke-Moon run cmd/main -- stats fixtures/valid-single.mrc

Write-Output "MoonMARC acceptance checks passed."
