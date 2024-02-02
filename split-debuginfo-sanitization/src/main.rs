struct SomeStruct {
    field: &'static str,
}

fn some_function(x: &mut SomeStruct) {
    println!("x: {:?}", x.field);
    let r = regex::Regex::new("abc.*def").unwrap();
    std::hint::black_box(r.captures(x.field));
    zzz(x.field);
    std::hint::black_box(x);
}

#[inline(never)]
fn zzz(x: &str) {
    std::hint::black_box(x);
}

fn main() {
    some_function(&mut SomeStruct {
        field: std::hint::black_box("1rfwrnvgvnwi3eie"),
    });
}
