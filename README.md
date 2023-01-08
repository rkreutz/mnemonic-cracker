# mnemonic-cracker

```bash
> mnemonic-cracker -h

OVERVIEW: A simple tool to try and find a mnemonic phrase from a partial
phrase.

This tool will try to brute force a mnemonic phrase given a partial mnemonic
phrase.

If used along with an address, using the -a flag, it will try to find a
mnemonic that matches the given address (defaulting to MetaMask's first
address).

If no address is provided, will try to check for address with non-zero
balances.

Supports mnemonic phrases of 12/15/18/21/24 words using English BIP-39 list of
words.

Must provide all words in the partial phrase, for positions which you don't
know the word use "?" and the tool will brute force using all the words in the
list.
If there are a few words which you believe might be part of the final mnemonic
phrase you may specify a list of them with a | separator for the position in
which you believe they are in.
If the provided words are not in the correct position, i.e. you don't know the
order of the words, you may use the flag --unsorted-list to permute all
possible sequences.

USAGE: mnemonic-cracker [--unsorted-list] [-a 0xaddress] [-v] [-p mnemonicPassword] [-l english] partial phrase can|provide|alternatives ? ? ? ? ? ? ? ? ?

ARGUMENTS:
  <partial-mnemonic>      The partial mnemonic phrase you have, with a ? for
                          words you do not know. You may specify alternatives
                          for a given position with | separated like:
                          razor|blade (will try both combinations)

OPTIONS:
  -a, --address <address> Ethereum address you'd hope to find
  -p, --password <password>
                          Passphrase for the mneumonic seed generation
  --unsorted-list         If the partial mnemonic phrase is not in the correct
                          order, i.e. the words provided are not in the correct
                          position.
  -v, --verbose
  -l, --language <language>
                          Language of the mnemonic phrase, options are: english
                          (default: english)
  -h, --help              Show help information.

```

## TODO

- [X] ~~Concurrently brute-force mnemonic phrases~~
- [ ] Use GPU for computation
- [ ] Add possibility to run a subset of the computation, i.e. separate workers in separate machines computing different parts of the same mnemonic phrases data set.
