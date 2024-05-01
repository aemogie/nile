use std::{
    env, fs, io,
    path::{Component, Path, PathBuf},
};

fn main() {
    let path = env::args()
        .skip(1)
        .next()
        .expect("Argument {root} not provided.");
    let root = Path::new(&path);
    let mut files = vec![];
    recurse_into_dir(root, &mut files, root).unwrap();
    files
        .iter()
        .map(|f| {
            f.components()
                .filter_map(|c| {
                    if let Component::Normal(s) = c {
                        Some(s.to_str())
                    } else {
                        None
                    }
                })
                .map(|c| c.unwrap().to_string())
                .collect::<Vec<_>>()
        })
        .map(|mut c| {
            let a = c.last_mut().unwrap();
            *a = a.strip_suffix(".nix").unwrap().to_owned();
            c
        })
        .for_each(|c| println!("{}", c.join(".")));
}

fn recurse_into_dir<'a>(root: &Path, acc: &mut Vec<PathBuf>, x: &Path) -> io::Result<()> {
    if x.is_dir() {
        for entry in fs::read_dir(x)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_dir() {
                recurse_into_dir(root, acc, &path)?;
            } else {
                acc.push(path.strip_prefix(root).unwrap().to_owned());
            }
        }
    } else {
        acc.push(x.to_owned());
    }
    Ok(())
}
