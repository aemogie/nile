lib: let
  inherit (builtins) filter groupBy mapAttrs head tail;
  inherit (lib) foldl' hasSuffix removeSuffix removePrefix pipe recursiveUpdate mapAttrsRecursive;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.path) subpath;
in let
  handlePath = root: path:
    pipe path [
      toString # convert it all to strings so nix doesnt copy everything implicitly and freak out
      (removePrefix (toString root))
      (removeSuffix (baseNameOf path))
      (t: "./${t}") # subpath.components freaks out on absolute paths
      subpath.components
      # (ab)using `mapAttrsRecursive` to always only update the innermost value
      (xs:
        foldl' (acc: x: mapAttrsRecursive (path: value: {${x} = null;}) acc)
        {${head xs} = null;}
        (tail xs))
      # since innermost is null, we need to refill it
      (mapAttrsRecursive (_: _: path))
    ];
  importRec = root:
    pipe root [
      listFilesRecursive
      (filter (hasSuffix ".nix"))
      (map toString)
      (groupBy (name: removeSuffix ".nix" (baseNameOf name)))
      (mapAttrs (_: map (handlePath root)))
      (mapAttrs handleGroup)
    ];
  # just merge for now
  handleGroup = group: definitions:
    pipe definitions [
      (foldl' recursiveUpdate {})
      (mapAttrsRecursive (_: import))
    ];
in {
  inherit importRec handlePath handleGroup;
  test = importRec ../test;
}
