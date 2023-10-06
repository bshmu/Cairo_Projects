use debug::PrintTrait;
use traits::{TryInto, Into};
use array::{ArrayTrait, SpanTrait};
use integer::BoundedInt;
use option::OptionTrait;
use cairo_json::simple_json::{Json, JsonTrait};
use alexandria_ascii::ToAsciiTrait;
use alexandria_encoding::base64::Base64Encoder;

// #[derive(Drop, Serde)]
// struct Json {
//     members: Array<(felt252, Span<felt252>)>,
// }

fn create_json(name: Array<felt252>, desc: Array<felt252>) -> Json {
        let mut metadata = Json { members: Default::default() };
        metadata.add('name', name.span());
        metadata.add('desc', desc.span());
        return metadata;
    }

fn unpack_felt252(ref input: felt252) -> Span<u8> {
    let mut intermediate = ArrayTrait::<u8>::new();
    let mut input_u8 = 255;
    let mut input_u256: u256 = input.into();
    loop {
        if input_u256 == 0 {
            break ();
        }

        input_u8 = (input_u256 & 0xFF).try_into().unwrap();

        intermediate.append(input_u8);

        input_u256 = shr(input_u256, 8);
    };
    
    // Reverse intermediate array
    let mut i = intermediate.len() - 1;
    let mut output = ArrayTrait::<u8>::new();
    loop {
        if i == 0 {
            let val = *intermediate.at(i);
            output.append(val);
            break ();
        }
        let val = *intermediate.at(i);
        output.append(val);
        i -= 1;
    };

    return output.span();
}

fn fpow(x: u256, n: u256) -> u256 {
    let y = x;
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return x;
    }
    let double = fpow(y * x, n / 2);
    if (n % 2) == 1 {
        return x * double;
    }
    return double;
}

fn shr(x: u256, n: u256) -> u256 {
    let result = x / fpow(2, n);
    return result;
}

fn main(name: Array<u8>, desc: Array<u8>) -> Array<u8> {

    // Assumes long strings are represented by an array of u8s

    // Initialize arrays to store felts that will be converted into JSON
    let mut name_ascii = ArrayTrait::<felt252>::new();
    let mut desc_ascii = ArrayTrait::<felt252>::new();

    // Convert arrays of uints into felts
    let mut i = 0;
    loop {
        if i == name.len() {
            break ();
        }
        let mut name_i = *name.at(i);
        
        // Convert uint into ascii felt using Alexandria
        let mut name_ascii_i: felt252 = name_i.to_ascii();
        
        // Append to the main array
        name_ascii.append(name_ascii_i);

        i += 1;
    };

    i = 0;
    loop {
        if i == desc.len() {
            break ();
        }
        let mut desc_i = *desc.at(i);

        // Convert uint into ascii felt using Alexandria
        let mut desc_ascii_i: felt252 = desc_i.to_ascii();
        
        // Append to the main array
        desc_ascii.append(desc_ascii_i);

        i += 1;
    };

    // Create the JSON
    // [('name', name_ascii), ('desc': desc_ascii)]
    let json = create_json(name_ascii, desc_ascii);
    
    // Break down each felt in the JSON into a u8
    let mut json_u8 = ArrayTrait::<u8>::new();
    i = 0;
    loop {
        if i == json.members.len() {
            break ();
        }
        
        // loop through the key and value pairs
        let (mut json_key_i, mut json_val_i) = *json.members.at(i);

        // felt252 keys "name" and "desc" need to further broken down into u8 arrays
        let json_key_i_u8 = unpack_felt252(ref json_key_i);

        let mut j= 0;
        loop {
            if j == json_key_i_u8.len() {
                break ();
            }

            let json_key_i_j_u8 = *json_key_i_u8.at(j);
            json_u8.append(json_key_i_j_u8);
            
            j += 1;
        };

        j = 0;
        loop {
            if j == json_val_i.len() {
                break ();
            }

            // values are an array of ascii characters, so should have no issue fitting into u8
            let mut json_val_i_j = *json_val_i.at(j);
            let json_val_i_j_u8 = unpack_felt252(ref json_val_i_j);

            let mut k = 0;
            loop {
                if k == json_val_i_j_u8.len() {
                    break ();
                }
                let json_val_i_j_u8_k = *json_val_i_j_u8.at(k);
                json_u8.append(json_val_i_j_u8_k);
                k += 1;
            };

            j += 1;
        };

        i += 1;
    };

    // Encode to base64
    let encoded_json = Base64Encoder::encode(json_u8);
    return encoded_json;
}


fn print_array(arr: Array<u8>) {
    let mut i = 0;
    loop {
        if i == arr.len() {
            break ();
        }
        let mut val = *arr.at(i);
        val.print();
        i += 1;
    }
}

fn print_span(spn: Span<u8>) {
    let mut i = 0;
    loop {
        if i == spn.len() {
            break ();
        }
        let mut val = *spn.at(i);
        val.print();
        i += 1;
    }
}


#[test]
#[available_gas(99999999999999999)]
fn test() {
    // Test arrays
    let mut test_name = ArrayTrait::<u8>::new();
    test_name.append(116); // t
    test_name.append(101); // e
    test_name.append(115); // s
    test_name.append(116); // t

    let mut test_desc = ArrayTrait::<u8>::new();
    test_desc.append(104); // h
    test_desc.append(101); // e
    test_desc.append(108); // l
    test_desc.append(108); // l
    test_desc.append(111); // o
    test_desc.append(32); // (space)
    test_desc.append(119); // w
    test_desc.append(111); // o
    test_desc.append(114); // r
    test_desc.append(108); // l
    test_desc.append(100); // d

    let encoded_array = main(test_name, test_desc);
    print_array(encoded_array);

}