# Compact Language Development

This guide covers development with the Midnight Compact language in the development platform.

## Overview

The platform includes full support for Midnight's Compact language, including:
- Syntax highlighting and IntelliSense
- Compiler integration
- File associations
- Format on save
- Linting

## VS Code Extension

### Pre-installed Extension

The platform comes with the official Midnight Compact extension (v0.2.13) pre-installed. This extension provides:

- **Syntax Highlighting** - Full syntax support for `.compact` files
- **IntelliSense** - Auto-completion and hover information
- **Error Detection** - Real-time error checking
- **Formatting** - Automatic code formatting
- **Snippets** - Common code snippets

### Extension Features

#### File Associations
- `.compact` - Compact contract files
- `.zk` - Zero-knowledge circuit files

#### Language Features
- Syntax highlighting
- Bracket matching
- Auto-indentation
- Code folding
- Comment toggling

#### Compiler Integration
- Compile on save
- Error highlighting
- Output panel for compiler messages

## Working with Compact Files

### Creating a New Contract

1. **Using the Template**
   ```bash
   midnight new my-token
   cd /workspace/projects/my-token
   ```

2. **Manual Creation**
   - Create a new file with `.compact` extension
   - VS Code will automatically apply Compact language support

### File Structure

```
my-project/
├── contracts/
│   ├── Token.compact      # Main contract
│   ├── Utils.compact      # Utility functions
│   └── Types.compact      # Type definitions
├── test/
│   └── token.test.js      # JavaScript tests
├── build/                 # Compiler output
└── Makefile              # Build commands
```

### Compiling Contracts

#### Using Make
```bash
make compile
```

#### Using Midnight CLI
```bash
midnight compile
```

#### Direct Compiler
```bash
compactc contracts/Token.compact
```

### VS Code Settings

The following settings are pre-configured for Compact development:

```json
{
  "files.associations": {
    "*.compact": "compact",
    "*.zk": "compact"
  },
  "[compact]": {
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true
  },
  "midnight.compact": {
    "formatOnSave": true,
    "lintOnSave": true,
    "compiler": {
      "path": "/opt/midnight/bin/compactc",
      "outputDir": "build"
    }
  }
}
```

## Example Contract

Here's a simple token contract in Compact:

```compact
// Token.compact
contract Token {
    // State variables
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Constructor
    constructor(string _name, string _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = _initialSupply * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // View functions
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
    
    // Transfer function
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    // Approve function
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    // Transfer from function
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
```

## Updating the Extension

### Check Current Version
```bash
code-server --list-extensions | grep midnight
```

### Update to Latest Version
```bash
update-midnight-extension
```

### Update to Specific Version
```bash
update-midnight-extension 0.2.14
```

## Extension Configuration

### Compiler Path
If the compiler is in a different location:
```json
{
  "midnight.compact.compiler.path": "/custom/path/to/compactc"
}
```

### Output Directory
Change where compiled files are saved:
```json
{
  "midnight.compact.compiler.outputDir": "dist"
}
```

### Format Options
```json
{
  "midnight.compact.format.indentSize": 4,
  "midnight.compact.format.useTabs": false
}
```

## Troubleshooting

### Extension Not Working

1. **Check Installation**
   ```bash
   code-server --list-extensions
   ```

2. **Reinstall Extension**
   ```bash
   update-midnight-extension
   ```

3. **Check Logs**
   - Open VS Code
   - View → Output
   - Select "Midnight Compact" from dropdown

### Compiler Not Found

1. **Verify Installation**
   ```bash
   which compactc
   ```

2. **Check PATH**
   ```bash
   echo $PATH | grep midnight
   ```

3. **Update Settings**
   - File → Preferences → Settings
   - Search for "midnight.compact.compiler"
   - Update path if needed

### Syntax Highlighting Not Working

1. **Check File Association**
   - Ensure file has `.compact` extension
   - Or manually set language mode: Ctrl+K M → Compact

2. **Reload Window**
   - Ctrl+Shift+P → "Developer: Reload Window"

## Best Practices

1. **Use Type Annotations** - Always specify types for better IntelliSense
2. **Enable Format on Save** - Keeps code consistent
3. **Use Linting** - Catches errors early
4. **Organize Imports** - Keep imports at the top
5. **Comment Complex Logic** - Use JSDoc-style comments
6. **Test Thoroughly** - Write comprehensive tests

## Resources

- [Midnight Documentation](https://docs.midnight.network)
- [Compact Language Specification](https://docs.midnight.network/compact)
- [Extension Repository](https://github.com/midnight-ntwrk/vscode-compact)
- [Example Contracts](https://github.com/midnight-ntwrk/examples)

## Support

For issues with the Compact extension:
- GitHub Issues: [midnight-ntwrk/vscode-compact](https://github.com/midnight-ntwrk/vscode-compact/issues)
- Discord: [Midnight Network Discord](https://discord.gg/midnight)