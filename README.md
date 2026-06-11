vim-code-runner
============

Run code snippet or code file in vim for multiple languages: **C, C++, Java,
JavaScript, PHP, Python, Perl, Ruby, Go, Lua**, etc.

## Features

* Run code in current buffer
* View code output in split window
* Support user input in output window when the program reads from standard input
* Make the command configable, user can override the settings
* Press `q` in output window to close it

## Supported vim version

- vim 8.1+ (require the new `terminal` feature, [reference](https://www.vim.org/vim-8.1-released.php))
- [Neovim 0.3.8+](https://github.com/neovim/neovim)

## Configurations

#### Key-bindings
By default, it binds `<leader>B` to run the code snippet. User can cutomize it like below:

```vim
nmap <silent><leader>B <plug>CodeRunner
```

#### Command map
User can define the command mapping like below, mapping defined here will
override the default one. More details can be found with command
`:h CodeRunner`.

```vim
let g:code_runner_command_map = {
      \ 'python' : 'python $fileName'
      \}
```
#### Save before execution
By default, the file is auto-saved before execution. To disable:

```vim
let g:code_runner_save_before_execute = 0
```

#### Reuse output window
By default, if the output window already exists, it will be reused instead of
opening a new split.

```vim
let g:code_runner_reuse_output_window = 0  " always open new split
```

#### Focus output window
By default, focus stays in the editor after running code. Set this to 1 to
focus the output window instead (useful when program requires input):

```vim
let g:code_runner_focus_output_window = 1
```

## TODOs
* ~~Prevent infinite-loop~~ (Update on 2021/09/16: just press Ctrl+C in output window to stop the program)
* ~~Fix the output window~~ (Update on 2021/09/16: with vim 8's terminal feature, now the plugin supports user input. Check [PR#3](https://github.com/xianzhon/vim-code-runner/pull/3))

## Thanks
* vim-easygrep
