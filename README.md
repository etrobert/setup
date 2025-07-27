# hi

```sh
echo 'hi2'
```

```js
console.log("biiiitch");

const k = () => 2;

console.log(k());
```

```
echo 'hi'

```

# setup

Dotfiles and other configurations using stow

Each folder is the configuration for a specific tool

`usage: stow folder`

```sh
echo 'hi'
```

```python3
print('hi')
```

```javascript
console.log("hi");
```

## Additional configuration steps

### Font

Download and install [Fira Code](https://github.com/tonsky/FiraCode).

Download and install [Fira Code Nerd Font](https://www.nerdfonts.com/font-downloads). This is used to display icons in the terminal, ex in Neovim.

### VSCode

1. Launch VSCode once to create `$HOME/.config/'Code - OSS'`
2. stow vscode
3. run the script `vscode-extensions install`

### Firefox

1. `mkdir ~/.mozilla/firefox/s0tnglli.etienne-robert`
2. Create a new Profile in `about:profiles` using the newly created folder
3. stow firefox

## Ressources

For more informations see:

- [man stow](https://www.gnu.org/software/stow/manual/stow.html)
- [Using GNU Stow to manage your dotfiles](http://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html)
