let corp_env = (^@bash@ --noprofile --norc -c '
  source "$("@sops_cached@" "@corp_env@")" && source "$("@sops_cached@" "@corp_tokens@")" && "@env@" -0
' | split row (char nul)
  | where {|entry| $entry != '' }
  | parse --regex '(?s)^(?<name>[^=]+)=(?<value>.*)$'
  | reduce --fold {} {|entry, vars| $vars | insert $entry.name $entry.value }
  | reject --optional PWD FILE_PWD CURRENT_FILE NU_VERSION SHLVL OLDPWD _)
load-env ($corp_env | update PATH {|vars| $vars.PATH | split row (char esep) })

def --wrapped corp-g [...args: string] {
  if $env.PWD =~ '/(arcadia|cloudia)' {
    ^arc ...$args
  } else {
    ^git ...$args
  }
}
