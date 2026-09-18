$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$logic = Join-Path $root 'Source Server\Game.Logic'
$map = Get-Content (Join-Path $logic 'Phy\Maps\Map.cs') -Raw
$player = Get-Content (Join-Path $logic 'Phy\Object\Player.cs') -Raw
$fall = Get-Content (Join-Path $logic 'Actions\LivingFallingAction.cs') -Raw

if ($map -notmatch 'HasCharacterSupport') { throw 'Missing deterministic terrain support helper.' }
if ($map -notmatch 'return left && right;') { throw 'One-sided edge support must not keep a character floating.' }
if ($map -notmatch 'stepY \* 2 \+ 3') { throw 'Walk landing scan must use vertical step window.' }
if ($map -match 'x1 > this\._bound\.Width') { throw 'Walk bound check still accepts x == width.' }

$start = [regex]::Match($player, '(?s)public override void StartMoving\(int delay, int speed\).*?\n\s*}')
if (-not $start.Success) { throw 'Player delayed StartMoving override missing.' }
if ($start.Value -match 'm_x\s*=|m_y\s*=|FindYLine') { throw 'Player StartMoving must not teleport to the landing point.' }
if ($start.Value -notmatch 'base\.StartMoving\(delay, speed\)') { throw 'Player must delegate settling to Living.' }

if ($fall -notmatch 'previousTargetY') { throw 'Falling action must detect terrain changes while airborne.' }
if ($fall -notmatch 'FindYLineNotEmptyPointDown\(this\.m_toX, this\.m_living\.Y\)') { throw 'Falling action must revalidate the authoritative landing point.' }
if ($fall -notmatch 'previousTargetY != this\.m_toY') { throw 'Changed landing point must be resent to clients.' }

Write-Output 'TERRAIN_CHARACTER_SETTLE_SMOKE=PASS'
