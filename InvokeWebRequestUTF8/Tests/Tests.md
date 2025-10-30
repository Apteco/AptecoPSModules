
This call

```PowerShell
Invoke-WebRequestUTF8 -Method post -Uri https://dummyjson.com/posts/add -ContentType "application/json" -Body ([PSCustomObject]@{ "title"="hellö wörld";"body"="my nöw body";"userId"=200 } | Convertto-json)
```

will return something like

```PowerShell
Invoke-WebRequestUTF8 -Method post -Uri https://dummyjson.com/posts/add -ContentType "application/json" -Body ([PSCustomObject]@{ "title"="hellö wörld";"body"="my nöw body";"userId"=200 } | Convertto-json) | fl


Content          : {"id":252,"title":"hellö wörld","body":"my nöw body","userId":200}
OriginalResponse : {"id":252,"title":"hell?? w??rld","body":"my n??w body","userId":200}

```