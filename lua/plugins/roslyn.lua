return {
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    dependencies = {
      {
        -- By loading as a dependencies, we ensure that we are available to set
        -- the handlers for roslyn
        "tris203/rzls.nvim",
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require("rzls").setup({})
        end,
      },
    },
    config = function()
      require("roslyn").setup({
        args = {
          "--stdio",
          "--logLevel=Information",
          "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
          "--razorSourceGenerator=" .. vim.fs.joinpath(
            vim.fn.stdpath("data") --[[@as string]],
            "mason",
            "packages",
            "roslyn",
            "libexec",
            "Microsoft.CodeAnalysis.Razor.Compiler.dll"
          ),
          "--razorDesignTimePath=" .. vim.fs.joinpath(
            vim.fn.stdpath("data") --[[@as string]],
            "mason",
            "packages",
            "rzls",
            "libexec",
            "Targets",
            "Microsoft.NET.Sdk.Razor.DesignTime.targets"
          ),
        },
        ---@diagnostic disable-next-line: missing-fields
        config = {
          handlers = require("rzls.roslyn_handlers"),
          settings = {
            ["csharp|background_analysis"] = {
              dotnet_analyzer_diagnostics_scope = "fullSolution",
              dotnet_compiler_diagnostics_scope = "fullSolution",
            },
            ["csharp|inlay_hints"] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,

              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
            ["csharp|code_lens"] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
      })

      vim.keymap.set("n", "<leader>p", function()
        local clients = vim.lsp.get_clients()
        for _, value in ipairs(clients) do
          if value.name == "roslyn" then
            vim.notify("roslyn client found")
            value.rpc.request("workspace/diagnostic", { previousResultIds = {} }, function(err, result)
              if err ~= nil then
                print(vim.inspect(err))
              end
              if result ~= nil then
                local diags = {}
                local seen = {}
                for _, diag in ipairs(result.items) do
                  local filepath = diag.uri:gsub("file:///", "")
                  if #diag.items > 0 then
                    for _, diag_line in ipairs(diag.items) do
                      if diag_line.severity == 1 then
                        local hash = diag_line.message .. diag_line.range.start.line .. diag_line.range.start.character
                        if seen[hash] == nil then
                          local s = {
                            text = diag_line.message,
                            lnum = diag_line.range.start.line,
                            col = diag_line.range.start.character,
                            filename = filepath,
                          }
                          table.insert(diags, s)
                          seen[hash] = true
                        end
                      end
                    end
                  end
                end
                vim.fn.setqflist(diags)
                vim.cmd("copen")
              end
            end)
          end
        end
      end, { noremap = true, silent = true })
    end,
    init = function()
      -- we add the razor filetypes before the plugin loads
      vim.filetype.add({
        extension = {
          razor = "razor",
          cshtml = "razor",
        },
      })
    end,
  },
}
