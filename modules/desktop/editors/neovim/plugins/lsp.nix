{
  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<F2>" = "rename";
          };
        };

        servers = {
          # ccls.enable = true;
          clangd.enable = true;
          hls.enable = true;
          lua-ls.enable = true;
          # pyright.enable = true;
          ruff.enable = true;
          ruff-lsp.enable = true;
          texlab.enable = true;
          zls.enable = true;
        };
      };

      lsp-format.enable = true;

      lspkind = {
        enable = true;

        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            luasnip = "[snip]";
            buffer = "[buffer]";
            neorg = "[neorg]";
          };
        };
      };

      lspsaga.enable = true;

      lsp-status.enable = true;
    };
  };
}
