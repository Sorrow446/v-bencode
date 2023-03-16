# v-bencode
Bencode library for V.

## Setup
`v install Sorrow446.vbencode`
```v
import sorrow446.vbencode as bencode
```

## Examples
#### Decode, prettify, and write to JSON file
```v
// returns map[string]json2.Any
dec := bencode.decode('1.torrent')!

// Always prettify when printing the whole object or writing it to a file. Converts to UTF-8 with 4 spaces.
os.write_file('out.json', bencode.prettify(dec))!
```
#### Accessing values with struct
```v
struct Info {
mut:
    name string
    files []struct {
        length i64
        path   []string
    }
}

struct Data {
mut:
    announce string
    info Info
}

d := json.decode(Data, dec.str())!
println(d.announce)

for file in d.info.files {
    println(file.path[0])
}
```

#### Accessing values without struct
```v
announce := dec.as_map()['announce']!
println(announce.str())

info := dec.as_map()['info']!
files := info.as_map()['files']!
for file in files.arr() {
    path := file.as_map()['path']!
    println(path.arr()[0].str())
}
```
