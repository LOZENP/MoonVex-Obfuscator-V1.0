# 🌙 MoonVex Obfuscator V1.0

**Moonvex Obfuscator 1.0**

By Rodgie 

## 🔥 Features

- ✅ **3-Layer XOR Encryption** 
- ✅ **50-80 Vararg Parameters**
- ✅ **3000-8000 Dummy Constants**
- ✅ **VM Bytecode Execution** 
- ✅ **ProxifyLocals**
- ✅ **Control Flow Obfuscation**
- ✅ **Modular Architecture**
- ✅ **Works on Termux**
- ✅ **Roblox Executor Compatible**

## 📁 File Structure

```
moonvex/
├── main.lua          # Main entry point
├── config.lua        # Configuration settings
├── util.lua          # Utility functions
├── namegen.lua       # Variable name generator
├── encoder.lua       # Encryption functions
├── vm.lua            # VM bytecode generator
├── cli.lua           # Command line interface
└── README.md         # This file
```

##  Installation

### On Termux (Android):
```bash
pkg install lua
cd moonvex
lua cli.lua input.lua output.lua
```

### On Linux/Mac:
```bash
cd moonvex
lua cli.lua input.lua output.lua
```

## 📖 Usage

### Basic Usage:
```bash
lua cli.lua script.lua obfuscated.lua
```

### Disable Watermark:
```bash
lua cli.lua -w script.lua obfuscated.lua
```

### Custom Complexity:
```bash
lua cli.lua -c 5 script.lua obfuscated.lua
```

### Verbose Output:
```bash
lua cli.lua -v script.lua obfuscated.lua
```

## 🔧 Programmatic Usage

```lua
local MoonVex = require("main")

-- Obfuscate string
local code = 'print("Hello World")'
local obfuscated = MoonVex.obfuscate(code)
print(obfuscated)

-- Obfuscate file
MoonVex.obfuscateFile("input.lua", "output.lua", {
    watermark = true,
    encryptionLayers = 3,
    complexityMultiplier = 5
})
```

## ⚙️ Configuration

Edit `config.lua` to customize:

```lua
{
    watermark = true,              -- Add watermark
    encryptionLayers = 3,          -- XOR layers (1-5)
    varargMin = 50,                -- Min vararg params
    varargMax = 80,                -- Max vararg params
    dummyConstantsMin = 3000,      -- Min dummy data
    dummyConstantsMax = 8000,      -- Max dummy data
    complexityMultiplier = 3,      -- Instruction complexity
    removeNewlines = true,         -- Single line output
    proxyCount = 10,               -- Proxy variables
    controlFlowObfuscation = true  -- State machine
}
```

## 🎯 Supported Lua Functions

Currently supports:
- `print()`
- `warn()`
- `wait()`
- `task.wait()`

## 🔨 Modifying Modules

### Adding Custom Encryption:
Edit `encoder.lua` and add your function:
```lua
function encoder.customEncrypt(data)
    -- Your encryption here
    return encrypted
end
```

### Adding New Instructions:
Edit `vm.lua` in the `parseCode` function:
```lua
elseif line:match("yourfunction") then
    -- Handle your function
end
```

### Changing Name Generation:
Edit `namegen.lua` to customize variable names.

## 🐛 Troubleshooting

### "Expected identifier" Error:
- Make sure you're using the fixed version
- Check that input file is valid Lua

### Works in Termux but not Roblox:
- Ensure no `loadstring()` restrictions
- Check executor compatibility

### Output too large:
- Reduce `dummyConstantsMax` in config
- Lower `complexityMultiplier`

## 📝 TODO

- [ ] Full Lua parser integration
- [ ] More instruction types
- [ ] GUI version
- [ ] Online web version
- [ ] Deobfuscator detection

## 🤝 Contributing

1. Fork the repo
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

## 📜 License

MIT License - if you want to modify this Obfuscator Credits me Rodgie - Shizo

## ⚠️ Disclaimer

This tool is for educational purposes. Don't use for malicious purposes.

## 🔗 Links

- GitHub: [?]
- Discord: [SOON]
- Website: [SOON]

---

Made with 💙 by Shizo
