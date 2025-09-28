set -Ux VISUAL nvim
set -Ux EDITOR nvim

# This a tricky one.
# Inside a nvim started we set HTTP(S)_PROXY for Copilot to work.
# This is done specifically for neovim, so not to touch any other tools.
# However, if terminal is started from inside neovim, PROXY vars are set,
# and this might break other tools, especially in corporate environment.
# Thus, we need to unset this variables.
# Since HTTP(S)_PROXY are common vars, we would like to unset them only if
# they were specifically set for neovim.
if test -n "$NVIM" && test -n "$MYVIMRC"
    set --unexport HTTP_PROXY
    set --unexport HTTPS_PROXY
    set --unexport http_proxy
    set --unexport https_proxy

    set --unexport OPENAI_API_KEY
    set --unexport GEMINI_API_KEY
    set --unexport CODESTRAL_API_KEY
    set --unexport DEEPSEEK_API_KEY
    set --unexport TAVILY_API_KEY
    set --unexport MORPH_API_KEY
    set --unexport CORP_LLM_API_KEY
end
