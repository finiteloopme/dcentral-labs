# Steps

```bash
# Initialise an anchor program
anchor init counter-prg
# Change to counter program folder
cd counter-prg
# Build the anchor code base
anchor build
# Test the counter program
anchor test
cd ..
mkdir sol-using-go
cd sol-using-go
# init go module
go mod init github.com/finiteloopme/dcentral-labs/anchor-golang/sol-using-go

# get go-lang generator
go get -u github.com/gagliardetto/anchor-go
anchor-go -src=../counter-prg/target/idl/counter_prg.json
```
