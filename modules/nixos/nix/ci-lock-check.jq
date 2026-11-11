# True when $new only moves locked versions forward from $old.
# The server upgrade check and the update workflow both run this, each with one lock file per variable.
def structure: del(.nodes) + {nodes: (.nodes | map_values(del(.locked)))};
def source: del(.rev, .narHash, .lastModified, .revCount);
($old | length) == 1 and ($new | length) == 1 and (
$old[0] as $old | $new[0] as $new |
($old | structure) == ($new | structure)
and all($new.nodes | to_entries[];
  .key as $key | .value.locked as $next | $old.nodes[$key].locked as $prev
  | ($prev | source) == ($next | source)
  and ($prev == $next or (
    ($prev.lastModified | type) == "number"
    and ($next.lastModified | type) == "number"
    and $prev.lastModified <= $next.lastModified))))
