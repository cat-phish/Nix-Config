-- debug diagnostics with AI and Google
return {
   'piersolenski/wtf.nvim',
   event = 'VeryLazy',
   dependencies = {
      'MunifTanjim/nui.nvim',
   },
   opts = {
      -- Default AI popup type
      popup_type = 'popup',
      -- An alternative way to set your API key
      -- openai_api_key = '',
      -- ChatGPT Model
      openai_model_id = 'gpt-3.5-turbo',
      -- Send code as well as diagnostics
      context = true,
      -- Set your preferred language for the response
      language = 'english',
      -- Any additional instructions
      additional_instructions = nil,
      -- Default search engine, can be overridden by passing an option to WtfSeatch
      search_engine = 'google',
      -- Callbacks
      hooks = {
         request_started = nil,
         request_finished = nil,
      },
      -- Add custom colours
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
   },
   keys = {
      {
         '<leader>cD',
         mode = { 'n', 'x' },
         function()
            require('wtf').ai()
         end,
         desc = 'Debug diagnostic with AI',
      },
      {
         mode = { 'n' },
         '<leader>cG',
         function()
            require('wtf').search()
         end,
         desc = 'Search diagnostic with Google',
      },
   },
}
