vim-code-runner
============

Run code snippet or code file in vim for multiple languages: **C, C++, Java,
JavaScript, PHP, Python, Perl, Ruby, Go, Lua**, etc.

## Features

* Run code in current buffer
* View code output in split window
* Support user input in output window when the program reads from standard input
* Make the command configable, user can override the settings

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
let g:CodeRunnerCommandMap = {
      \ 'python' : 'python $fileName'
      \}
```
#### Save before execution

By default, after file modification, user should save it first to check the
execution result of the latest file. With below setting, it will auto-save
before the code execution.

```vim
let g:code_runner_save_before_execute = 1
```

## TODOs
* ~~Prevent infinite-loop~~ (Update on 2021/09/16: just press Ctrl+C in output window to stop the program)
* ~~Fix the output window~~ (Update on 2021/09/16: with vim 8's terminal feature, now the plugin supports user input. Check [PR#3](https://github.com/xianzhon/vim-code-runner/pull/3))

## Thanks
* vim-easygrep
