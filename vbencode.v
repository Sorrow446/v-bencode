module vbencode

import os
import strings
import x.json2

struct Decoder {
mut:
	f os.File
}

fn (mut decoder Decoder) read_str_of_len(str_len int) !string {
	if str_len == 0 {
		return ''
	}
	mut buf := []u8{len: str_len}
	decoder.f.read(mut buf)!
	return buf.bytestr()
}

fn (mut decoder Decoder) read_int_until(until string) !i64 {
	mut len_str := ''
	for {
		c := decoder.read_str_of_len(1)!
		if c == until {
			break
		}
		len_str += c
	}

	len := len_str.i64()
	if len < 0 {
		return error('string length can\'t be negative')
	}
	return len
}

fn (mut decoder Decoder) read_str() !string {
	len := decoder.read_int_until(':')!
	s := decoder.read_str_of_len(int(len))!
	return s
}

fn (mut decoder Decoder) read_pieces() !string {
	len := decoder.read_int_until(':')!
	mut buf := []u8{len: int(len)}
	decoder.f.read(mut buf)!
	return buf.hex()
}

fn (mut decoder Decoder) read_list() ![]json2.Any {
	mut list := []json2.Any{}
	for {
		c := decoder.read_str_of_len(1)!
		if c == 'e' {
			break
		}
		item := decoder.read_interface_type(c, false)!
		list << item
	}
	return list
}

fn (mut decoder Decoder) read_interface_type(t string, pieces bool) !json2.Any{
	mut v := json2.Any(0)
	match t {
		'i' {
			v = decoder.read_int_until('e')!
		}
		'l' {
			v = decoder.read_list()!
		}
		'd' {
			v = decoder.read_dict()!
		}
		else {
			decoder.f.seek(-1, .current)!
			if pieces {
				v = decoder.read_pieces()!
			} else {
				v = decoder.read_str()!
			}		
		}
	}
	return v
}

fn (mut decoder Decoder) read_dict() !map[string]json2.Any{
	mut dict := map[string]json2.Any{}
	for {
		key := decoder.read_str()!
		t := decoder.read_str_of_len(1)!
		pieces := key == 'pieces'
		item := decoder.read_interface_type(t, pieces)!
		dict[key] = item
		next_char := decoder.read_str_of_len(1)!
		if next_char == 'e' {
			break
		}
		decoder.f.seek(-1, .current)!
	}
	return dict
}

pub fn prettify(f json2.Any) string {
	mut sb := strings.new_builder(4096)
	mut enc := json2.Encoder{
		newline: `\n`
		newline_spaces_count: 4
		escape_unicode: false
	}
	enc.encode_value(f, mut sb) or {}
	return sb.str()
}

pub fn decode(file_path string) !json2.Any{
	mut f := os.open_file(file_path, 'rb', 0o755)!
	defer { f.close() }

	mut decoder := &Decoder{f: f}

	t := decoder.read_str_of_len(1)!
	if t != 'd' {
		return error('first type must be a dictionary')
	}

	parsed := decoder.read_dict()!
	return parsed
}
