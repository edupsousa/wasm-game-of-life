(module
  (import "game" "memory" (memory 0))
  (import "game" "cols" (global $cols i32))
  (import "game" "rows" (global $rows i32))
  (func $tick (export "tick")
    (local $cellCount i32)
    (local $i i32)
    (local.set $cellCount (call $getCellCount))
    (loop $cellsLoop
      (call $gameOfLife
        (local.get $i)
        (call $getCellValue (local.get $i))
      )
      (local.set $i (call $inc (local.get $i)))
      (br_if $cellsLoop (i32.lt_u (local.get $i) (local.get $cellCount)))
    )
    (memory.copy (i32.const 0) (local.get $cellCount) (local.get $cellCount))
  )
  (func $walk (param $i i32) (param $v i32)
    (local $neighIndex i32)
    (local $neighValue i32)
    (local.set $neighIndex (call $getIndexSouth (local.get $i)))
    (local.set $neighValue (call $getCellValue (local.get $neighIndex)))
    (if 
      (i32.and (i32.eq (local.get $v) (i32.const 1)) (i32.eqz (local.get $neighValue)))
      (then
        (call $setCellValue (local.get $i) (i32.const 0))
        (call $setCellValue (local.get $neighIndex) (i32.const 1))
      )
      (else)
    )
  )
  (func $zeroCell (param $i i32) (param $v i32)
    (call $setCellValue (local.get $i) (i32.const 0))
  )
  (func $invertCell (param $i i32)  (param $v i32)
    (if
      (i32.eqz (local.get $v))
      (then
        (call $setCellValue (local.get $i) (i32.const 1))
      )
      (else
        (call $setCellValue (local.get $i) (i32.const 0))
      )
    )
  )
  (func $getCellCount (result i32)
    (i32.mul (global.get $rows) (global.get $cols))
  )
  (func $inc (param $i i32) (result i32)
    (i32.add (local.get $i) (i32.const 1))
  )
  (func $getCellValue (param $i i32) (result i32)
    (i32.load8_u (local.get $i))
  )
  (func $setCellValue (param $i i32) (param $value i32)
    (i32.store8 (i32.add (call $getCellCount) (local.get $i)) (local.get $value))
  )
  (type $getIndexNeigh (func (param i32) (result i32)))
  (table $neighbors 8 funcref)
  (elem (i32.const 0) $getIndexNorth $getIndexEast $getIndexSouth $getIndexWest $getIndexNE $getIndexNW $getIndexSW $getIndexSE)
  (func $getIndexEast (param $i i32) (result i32)
    (local $e i32)
    (local.set $e (i32.add (local.get $i) (i32.const 1)))
    (if (result i32)
      (i32.eqz (i32.rem_u (local.get $e) (global.get $cols)))
      (then
        (i32.sub (local.get $e) (global.get $cols))
      )
      (else
        local.get $e
      )
    )
  )
  (func $getIndexWest (param $i i32) (result i32)
    (i32.sub
      (if (result i32)
        (i32.eqz (i32.rem_u (local.get $i) (global.get $cols)))
        (then
          (i32.add (local.get $i) (global.get $cols))
        )
        (else
          local.get $i
        )
      )
      (i32.const 1)
    )
  )
  (func $getIndexNorth (param $i i32) (result i32)
    (i32.sub
      (if (result i32)
        (i32.lt_u (local.get $i) (global.get $cols))
        (then
          (i32.add (local.get $i) (call $getCellCount))
        )
        (else
          local.get $i
        )
      )
      (global.get $cols)
    )
  )
  (func $getIndexSouth (param $i i32) (result i32)
    (local $s i32)
    (local.set $s (i32.add (local.get $i) (global.get $cols)))
    (if (result i32)
      (i32.gt_u (local.get $s) (call $getCellCount))
      (then
        (i32.sub (local.get $s) (call $getCellCount))
      )
      (else
        local.get $s
      )
    )
  )
  (func $getIndexNW (param $i i32) (result i32)
    (call $getIndexWest (call $getIndexNorth (local.get $i)))
  )
  (func $getIndexNE (param $i i32) (result i32)
    (call $getIndexEast (call $getIndexNorth (local.get $i)))
  )
  (func $getIndexSW (param $i i32) (result i32)
    (call $getIndexWest (call $getIndexSouth (local.get $i)))
  )
  (func $getIndexSE (param $i i32) (result i32)
    (call $getIndexEast (call $getIndexSouth (local.get $i)))
  )
  (func $countDeadAlive (param $i i32) (result i32 i32)
    (local $dead i32)
    (local $alive i32)
    (local $fnIndex i32)
    (loop $countLoop
      (call_indirect $neighbors (type $getIndexNeigh) 
        (local.get $i) 
        (local.get $fnIndex)
      )
      call $getCellValue
      (if (i32.eqz)
        (then (local.set $dead (call $inc (local.get $dead))))
        (else (local.set $alive (call $inc (local.get $alive))))
      )
      (local.set $fnIndex (call $inc (local.get $fnIndex)))
      (br_if $countLoop (i32.lt_u (local.get $fnIndex) (table.size $neighbors)))
    )
    local.get $dead
    local.get $alive
  )
  (func $gameOfLife (param $i i32) (param $v i32)
    (local $dead i32)
    (local $alive i32)
    (call $countDeadAlive (local.get $i))
    local.set $alive
    local.set $dead
    (if
      (i32.eqz (local.get $v))
      (then
        (if
          (i32.eq (local.get $alive) (i32.const 3))
          (then
            (call $setCellValue (local.get $i) (i32.const 1))
          )
        )
      )
      (else
        (if
          (i32.or
            (i32.lt_u (local.get $alive) (i32.const 2))
            (i32.gt_u (local.get $alive) (i32.const 3))
          )
          (then
            (call $setCellValue (local.get $i) (i32.const 0))
          )
        )
      )
    )
  )
)