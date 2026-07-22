BeforeAll {

    # Redirect the module's persistent store to an isolated temp folder, so tests
    # don't read or write the real local PSNotify store on the machine running them.
    $script:testStoreDir = Join-Path ([System.IO.Path]::GetTempPath()) "PSNotifyTests_$( [guid]::NewGuid() )"
    New-Item -Path $script:testStoreDir -ItemType Directory -Force | Out-Null
    $env:PSNOTIFY_HOME = $script:testStoreDir

    # Import the module (must happen after PSNOTIFY_HOME is set, it's read at import time)
    Import-Module $PSScriptRoot/../"PSNotify" -Force

}

AfterAll {
    Remove-Item Env:\PSNOTIFY_HOME -ErrorAction SilentlyContinue
    Remove-Item -Path $script:testStoreDir -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Mock channel' {

    BeforeAll {
        $script:mockFolder = Join-Path $script:testStoreDir "mock-messages"
        Add-MockChannel -Name "PesterMock" -Folder $script:mockFolder
    }

    It 'Writes a file per notification with the right content' {

        $filePath = Send-MockNotification -Name "PesterMock" -Title "Pester" -Text "Hello from Pester"

        $filePath | Should -Exist

        $content = Get-Content -Path $filePath -Raw | ConvertFrom-Json
        $content.name  | Should -Be "PesterMock"
        $content.title | Should -Be "Pester"
        $content.text  | Should -Be "Hello from Pester"

    }

    It 'Is retrievable via Get-MockChannel and Get-NotificationChannel' {

        (Get-MockChannel -Name "PesterMock").Name | Should -Be "PesterMock"
        (Get-NotificationChannel -Type Mock).Name  | Should -Contain "PesterMock"

    }

}

Describe 'Webhook channel' {

    BeforeAll {
        Add-WebhookChannel -Name "PesterWebhook" -Url "https://postman-echo.com/post"
    }

    It 'Encrypts the url at rest' {

        $channel = Get-WebhookChannel -Name "PesterWebhook"
        $channel.Definition.url | Should -Not -Be "https://postman-echo.com/post"

    }

    It 'POSTs the notification to the configured url' -Tag "Network" {

        $result = Send-WebhookNotification -Name "PesterWebhook" -Title "Pester" -Text "Hello via Webhook"
        $echo = $result | ConvertFrom-Json

        $echo.json.title | Should -Be "Pester"
        $echo.json.text  | Should -Be "Hello via Webhook"

    }

}

Describe 'Group notification dispatch' {

    BeforeAll {
        $script:groupMockFolder = Join-Path $script:testStoreDir "group-mock-messages"
        Add-MockChannel -Name "PesterGroupMock" -Folder $script:groupMockFolder
        Add-NotificationGroup -Name "PesterGroup"
        Add-NotificationGroupTarget -Group "PesterGroup" -Channel "PesterGroupMock" -Target "PesterGroupMock"
    }

    It 'Dispatches to Send-<Type>Notification by convention (no hardcoded per-type case)' {

        Send-GroupNotification -Name "PesterGroup" -Message "Hello group"

        $latest = Get-ChildItem -Path $script:groupMockFolder | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $latest | Should -Not -BeNullOrEmpty

        (Get-Content -Path $latest.FullName -Raw | ConvertFrom-Json).text | Should -Be "Hello group"

    }

}
