# paxchange

## Group Handling
### Pacman capabilities
- List ALL groups with ALL packages (`-Sgg`)
- List LOCAL groups with INSTALLED package (`-Qgg`)
  - only lists groups with at least one package installed

### Format
- New type: `::group <group>`
- Represents a pacman group
- can be automatically expanded to `pacman -Sgq <group>`

### Review
#### ✅ Step 1 - added package with no group
- When reviewing an added package, the option "g" allows to add a group
  - query before printing to give a preview of the groups?
- this then lists all available groups or uses the single group
  - or a different shortcut?
  - maybe just "g#", if it can be done with the handler
- Selecting a group does:
  1. remove all entries from that group from the selected package history files
  3. Add a "::group <group>" entry to the selected file
  4. Reevaluate

### Step 2 - uninstalled package with group
- when loading the hierarchy, synced groups are loaded and cached as well
- when handling an `-missing` package, ownership to synced groups is checked
- if the package belongs to an owned group, a different prompt is displayed. Options:
  - Install because group
  - expand group (and thus break group sync)
  - Color: blue maybe?
- expanding a group will remove it from the history and replace it with all installed packages from that group
  - via `pacman -Qgq <group>`
  - Reevaluate

### Step 3 - delete groups
- If expanding a group fails, add a special prompt
- informs that the group is missing and will be removed (yes, skip, quit)
- should always be the first steps

### Step 4 - removed package with group
- ignored for now, as this would require me to keep a cached copy of the groups
- this is overkill for something most likely rarely needed
- can still be added if it happens often

### ✅ Update
- no real changes
- `::group` entries are expanded before creating the diff
  - this means packages removed from groups are `+new`
  - and packages added to a group (not installed) are `-missing`
  - package added but already installed are detected as unchanged
  - ignore errors when expanding a group

### ✅ Install
- Only installs the group, not the packages of each group

## Drop Root
- Drop root permissions when running "update"
