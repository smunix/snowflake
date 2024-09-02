{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.editors.neovim;
in
{

  options.modules.desktop.editors.neovim =
    let
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.types) enum nullOr;
    in
    {
      enable = mkEnableOption "Spread the joy of neovim in our flake";
      package = mkPackageOption pkgs "neovim-developer" { };
      template = mkOption {
        type = nullOr (enum [
          "nixvim"
          "neovim-flake"
          "agasaya"
          "ereshkigal"
        ]);
        default = "neovim-flake";
        description = "Which Neovim configuration to setup.";
      };
    };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.template != "neovim-flake") {
      nixpkgs.overlays = [ inputs.nvim-nightly.overlays.default ];

      user.packages = attrValues (
        optionalAttrs (config.modules.develop.cc.enable == false) {
          inherit (pkgs) gcc nodejs-slim tree-sitter; # Treesitter
        }
      );
    })

    (mkIf (cfg.template == "neovim-flake") (
      let
        inherit (inputs) neovim-flake;
        overlay = _: prev: {
          neovim = neovim-flake.packages.${prev.system}.maximal.extendConfiguration {
            # pkgs = prev;
            modules = with lib; [
              {
                config.vim.theme = {
                  enable = true;
                  name = mkForce "catppuccin";
                };
                config.vim.languages = {
                  nix.enable = mkForce true;
                  python.enable = mkForce true;
                  rust = {
                    enable = mkForce true;
                    lsp.package = prev.rust-analyzer;
                    packages = {
                      inherit (prev) cargo;
                    };
                  };
                };
              }
            ];
          };
        };
      in
      {
        nixpkgs.overlays = [ overlay ];
        user.packages = attrValues { inherit (pkgs) lazygit neovim; };
      }
    ))

    (mkIf (cfg.template == "nixvim") {
      hm = {
        imports = [
          inputs.nixvim.homeManagerModules.nixvim
          ./neovim/plugins/barbar.nix
          ./neovim/plugins/comment.nix
          ./neovim/plugins/efm.nix
          ./neovim/plugins/floaterm.nix
          ./neovim/plugins/harpoon.nix
          ./neovim/plugins/lsp.nix
          ./neovim/plugins/lualine.nix
          ./neovim/plugins/markdown-preview.nix
          ./neovim/plugins/neorg.nix
          ./neovim/plugins/neo-tree.nix
          ./neovim/plugins/startify.nix
          ./neovim/plugins/tagbar.nix
          ./neovim/plugins/telescope.nix
          ./neovim/plugins/treesitter.nix
          ./neovim/plugins/vimtex.nix
        ];

        programs.nixvim = {
          enable = true;

          # colorschemes.ayu.enable = true;
          # colorschemes.gruvbox.enable = true;
          # colorschemes.nord.enable = true;
          colorschemes.one.enable = true;
          # colorschemes.onedark.enable = true;
          # colorschemes.vscode.enable = true;

          defaultEditor = true;

          package = cfg.package;

          viAlias = true;
          vimAlias = true;
          vimdiffAlias = true;

          luaLoader.enable = true;

          autoCmd = [
            # Vertically center document when entering insert mode
            {
              event = "InsertEnter";
              command = "norm zz";
            }
            # Open help in a vertical split
            {
              event = "FileType";
              pattern = "help";
              command = "wincmd L";
            }
            # Enable spellcheck for some filetypes
            {
              event = "FileType";
              pattern = [
                "tex"
                "latex"
                "markdown"
                "mkiv"
              ];
              command = "setlocal spell spelllang=en,fr";
            }
          ];

          globals = {
            # Disable useless providers
            loaded_ruby_provider = 0; # Ruby
            loaded_perl_provider = 0; # Perl
            loaded_python_provider = 0; # Python 2

            mapleader = " ";
            maplocalleader = " ";
          };

          highlight.Todo = {
            fg = "Blue";
            bg = "Yellow";
          };

          match.TODO = "TODO";

          keymaps =
            let
              normal =
                lib.mapAttrsToList
                  (key: action: {
                    mode = "n";
                    options.silent = true;
                    inherit action key;
                  })
                  {
                    "<Space>" = "<NOP>";

                    # Esc to clear search results
                    "<esc>" = ":noh<CR>";

                    # fix Y behaviour
                    Y = "y$";

                    # back and fourth between the two most recent files
                    "<C-c>" = ":b#<CR>";

                    # close by Ctrl+x
                    "<C-x>" = ":close<CR>";

                    # save by Space+s or Ctrl+s
                    "<leader>s" = ":w<CR>";
                    "<C-s>" = ":w<CR>";

                    # navigate to left/right window
                    "<leader>h" = "<C-w>h";
                    "<leader>l" = "<C-w>l";

                    # Press 'H', 'L' to jump to start/end of a line (first/last character)
                    L = "$";
                    H = "^";

                    # resize with arrows
                    "<C-Up>" = ":resize -2<CR>";
                    "<C-Down>" = ":resize +2<CR>";
                    "<C-Left>" = ":vertical resize +2<CR>";
                    "<C-Right>" = ":vertical resize -2<CR>";

                    # move current line up/down
                    # M = Alt key
                    "<M-k>" = ":move-2<CR>";
                    "<M-j>" = ":move+<CR>";

                    "<leader>rp" = ":!remi push<CR>";
                  };
              visual =
                lib.mapAttrsToList
                  (key: action: {
                    mode = "v";
                    # options.silent = true;
                    inherit action key;
                  })
                  {
                    # better indenting
                    ">" = ">gv";
                    "<" = "<gv";
                    "<TAB>" = ">gv";
                    "<S-TAB>" = "<gv";

                    # move selected line / block of text in visual mode
                    "K" = ":m '<-2<CR>gv=gv";
                    "J" = ":m '>+1<CR>gv=gv";
                  };
            in
            (
              [
                {
                  mode = "n";
                  key = "<C-t>";
                  action.__raw = ''
                    function()
                      require('telescope.builtin').live_grep({
                        default_text="TODO",
                        initial_mode="normal"
                      })
                    end
                  '';
                  options.silent = true;
                }
              ]
              ++ normal
              ++ visual
            );

          clipboard = {
            # Use system clipboard
            register = "unnamedplus";

            providers.wl-copy.enable = true;
          };

          opts = {
            # completeopt = [
            #   "menu"
            #   "menuone"
            #   "noeselect"
            # ];

            updatetime = 100; # Faster completion

            # Line numbers
            relativenumber = true; # Relative line numbers
            number = true; # Display the absolute line number of the current line
            hidden = true; # Keep closed buffer open in the background
            mouse = "a"; # Enable mouse control
            mousemodel = "extend"; # Mouse right-click extends the current selection
            splitbelow = true; # A new window is put below the current one
            splitright = true; # A new window is put right of the current one

            swapfile = false; # Disable the swap file
            modeline = true; # Tags such as 'vim:ft=sh'
            modelines = 100; # Sets the type of modelines
            undofile = true; # Automatically save and restore undo history
            incsearch = true; # Incremental search: show match for partly typed search command
            inccommand = "split"; # Search and replace: preview changes in quickfix list
            ignorecase = true; # When the search query is lower-case, match both lower and upper-case
            #   patterns
            smartcase = true; # Override the 'ignorecase' option if the search pattern contains upper
            #   case characters
            scrolloff = 8; # Number of screen lines to show around the cursor
            cursorline = false; # Highlight the screen line of the cursor
            cursorcolumn = false; # Highlight the screen column of the cursor
            signcolumn = "yes"; # Whether to show the signcolumn
            colorcolumn = "100"; # Columns to highlight
            laststatus = 3; # When to use a status line for the last window
            fileencoding = "utf-8"; # File-content encoding for the current buffer
            termguicolors = true; # Enables 24-bit RGB color in the |TUI|
            spell = false; # Highlight spelling mistakes (local to window)
            wrap = false; # Prevent text from wrapping

            # Tab options
            tabstop = 4; # Number of spaces a <Tab> in the text stands for (local to buffer)
            shiftwidth = 4; # Number of spaces used for each step of (auto)indent (local to buffer)
            expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
            autoindent = true; # Do clever autoindenting

            textwidth = 0; # Maximum width of text that is being inserted.  A longer line will be
            #   broken after white space to get this width.

            # Folding
            foldlevel = 99; # Folds with a level higher than this number will be closed
          };

          plugins = {
            barbecue.enable = true;

            cmp = {
              enable = true;
              settings = {
                snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
                mapping = {
                  "<C-d>" = "cmp.mapping.scroll_docs(-4)";
                  "<C-f>" = "cmp.mapping.scroll_docs(4)";
                  "<C-Space>" = "cmp.mapping.complete()";
                  "<C-e>" = "cmp.mapping.close()";
                  "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
                  "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
                  "<CR>" = "cmp.mapping.confirm({ select = true })";
                };
              };
            };

            cmp-nvim-lsp.enable = true;

            coq-nvim = {
              enable = true;
            };

            gitblame.enable = true;

            gitignore.enable = true;

            gitsigns = {
              enable = true;
              settings.signs = {
                add.text = "+";
                change.text = "~";
              };
            };

            haskell-scope-highlighting.enable = true;

            helm.enable = true;

            indent-blankline.enable = true;

            # https://www.youtube.com/watch?v=CPLdltN7wgE
            lazygit.enable = true;

            lightline.enable = true;

            luasnip.enable = true;

            nix.enable = true;

            nvim-autopairs.enable = true;

            nvim-colorizer = {
              enable = true;
            };

            oil.enable = true;

            transparent.enable = true;

            trim = {
              enable = true;
              settings = {
                highlight = true;
                ft_blocklist = [
                  "checkhealth"
                  "floaterm"
                  "lspinfo"
                  "neo-tree"
                  "TelescopePrompt"
                ];
              };
            };

          };
        };

      };
    })

    (mkIf (cfg.template == "ereshkigal" || cfg.template == "agasaya") {

      hm.programs.neovim = {
        enable = true;
        package = cfg.package;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        plugins = with pkgs.vimPlugins; [
          nvchad
          nvchad-ui
          rust-vim
          vim-nix
          yankring
          zig-vim
        ];
      };
    })

    (mkIf (cfg.template == "agasaya") {
      modules.develop.lua.enable = true;

      home.configFile = {
        agasaya-config = {
          target = "nvim";
          source = "${inputs.nvim-dir}";
          recursive = true;
        };

        agasaya-init = {
          target = "nvim/init.lua";
          text = ''
            -- THIS (`init.lua`) FILE WAS GENERATED BY HOME-MANAGER.
            -- REFRAIN FROM MODIFYING IT DIRECTLY!

            local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

            if not vim.loop.fs_stat(lazypath) then
                vim.fn.system({
                    "git",
                    "clone",
                    "--filter=blob:none",
                    "--single-branch",
                    "https://github.com/folke/lazy.nvim.git",
                    lazypath,
                })
            end

            vim.opt.runtimepath:prepend(lazypath)

            -- Point Nvim to correct sqlite path
            vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so"

            -- Call-forward Agasaya:
            require("config").init()
          '';
        };
      };
    })

    (mkIf (cfg.template == "ereshkigal") {
      modules.develop.lua.fennel.enable = true;

      home.configFile = {
        ereshkigal-config = {
          source = "${inputs.nvim-dir}";
          target = "nvim";
          recursive = true;
        };
        ereshkigal-init = {
          target = "nvim/init.lua";
          text = ''
            -- THIS (`init.lua`) FILE WAS GENERATED BY HOME-MANAGER.
            -- REFRAIN FROM MODIFYING IT DIRECTLY!

            local function fprint(string, ...)
                print(string.format(string, ...))
            end

            local function plugin_status(status)
                if not status then
                    return "start/"
                else
                    return "opt/"
                end
            end

            local function assert_installed(plugin, branch, status)
                local _, _, plugin_name = string.find(plugin, [[%S+/(%S+)]])
                local plugin_path = vim.fn.stdpath("data")
                    .. "/site/pack/packer/"
                    .. plugin_status(status)
                    .. plugin_name
                if vim.fn.empty(vim.fn.glob(plugin_path)) > 0 then
                    fprint(
                        "Couldn't find '%s'. Cloning a new copy to %s",
                        plugin_name,
                        plugin_path
                    )
                    if branch > 0 then
                        vim.fn.system({
                            "git",
                            "clone",
                            "https://github.com/" .. plugin,
                            "--branch",
                            branch,
                            plugin_path,
                        })
                    else
                        vim.fn.system({
                            "git",
                            "clone",
                            "https://github.com/" .. plugin,
                            plugin_path,
                        })
                    end
                end
            end

            assert_installed("wbthomason/packer.nvim", nil, true)
            assert_installed("rktjmp/hotpot.nvim", "nightly")

            -- Point Nvim to correct sqlite path
            vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so"

            if pcall(require, "hotpot") then
                require("hotpot").setup({
                    modules = { correlate = true },
                    provide_require_fennel = true,
                })
                require("core.init")
            else
                print("Failed to require Hotpot")
            end
          '';
        };
      };
    })
  ]);
}
