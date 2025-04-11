# NLS (Natural Language Shell)

**NLS** is a lightweight command‐line tool that lets you write plain English instructions and have them translated into corresponding bash commands. With a simple key binding (Ctrl+T) in your shell, NLS replaces your plain text with a valid bash command—no need to remember obscure syntax!

## Motivation

Have you ever wished you could simply tell your terminal what to do instead of memorizing arcane bash commands? NLS was created to bridge that gap by translating natural language into bash commands on the fly. Whether you're new to the shell or a seasoned geek looking for a productivity boost, NLS makes the command line more intuitive. Power you command line by AI!

## Features


- 🗣️ **Natural Language Translation:** Transform plain English instructions into precise bash commands.
- ⌨️ **Custom Key Binding:** Instantly trigger translation with **Ctrl+T**.
- 🌐 **Public API Integration:** Leverages the paid OpenAI API to generate commands.
- 🔑 **Free API Tokens:** I personally fund free tokens with limited usage (updated periodically). Contact me for a dedicated token.
- 💻 **OS & Shell Detection:** Automatically identifies your operating system and shell type for optimized command suggestions.
- 📌 **Persistent Setup:** Automatically adds itself to your shell’s configuration file (e.g. `~/.bashrc`, `~/.zshrc`, or `~/.profile`) for convenience; remove by deleting the marked configuration block.
- 📄 **Project Context Integration:** Optionally include a context file (absolute path) containing project-specific command documentation, which enriches the AI prompt to generate commands tailored to your project's conventions.



## Installation

### Step 1: Download the Script for Your Shell

Choose the version of NLS that fits your environment:

| **Shell Type**     | **Download Link**                                                 |
|--------------------|-------------------------------------------------------------------|
| Zsh                | [nls.zsh](https://github.com/DmytroHuzz/nls/blob/main/nls.zsh)    |
| Bash               | [nls.sh](https://github.com/DmytroHuzz/nls/blob/main/nls.sh)      |
| PowerShell         | *Coming soon*                                                     |

### Step 2: Execute the Script with Your API Token
**API Tokens**

For community use, here are a few example tokens with limited usage (subject to change):

- **Token 1:** `JkK6O8762a`
- **Token 2:** `JkK6O8762b`

⚠️ *I cover the API costs myself and update these tokens periodically. If you need your own individual token, please contact me directly.*

After downloading the script, run it from your terminal by executing:

```bash
. ./nls.{shell_type} {TOKEN} {CONTEXT_FILE}
```

Replace `{shell_type}` with `zsh`, `sh` or `ps1` as appropriate, and `{TOKEN}` with one of the provided API tokens (see above) or your own individual key if you have one. `{CONTEXT_FILE}` (optional): Provide the absolute path to a documentation file that contains project-specific command definitions. When supplied, the contents of this file are appended as additional context to the AI prompt, enabling it to generate commands tailored to your project's requirements.

**Once sourced, the script will:**

- Automatically detect your OS and shell type and include that info in the API request.
- Persist itself by appending a configuration block to your ~/.zshrc file, so the Ctrl+T shortcut stays active in future terminal sessions.

❌ **How to Remove It**

To remove the widget later, simply open your ~/.zshrc or ~/.bashrc file and delete the lines between:
```bash
# NLS_WIDGET_CONFIG_START
...
# NLS_WIDGET_CONFIG_END
```

## Usage

1. Open your terminal (with Zsh, Bash or PowerShell, depending on your download).
2. Type a plain English command describing what you want to do.
3. Press **Ctrl+T**.
4. Your plain text will be replaced with the corresponding bash command!

### Example

If you type:

```
list all files modified in the last 24 hours
```

and press **Ctrl+T**, NLS might replace it with:

```bash
find . -type f -mtime -1
```

## Contributing

Contributions are welcome! Please open issues or submit pull requests.

## License

This project is licensed under the [MIT License](LICENSE).

## Contact

For questions, feedback, or to request your individual API token, please email [dmyhuz@gmail.com](mailto:dmyhuz@gmail.com).
