/* -------------------------------------------------------------
 *  Файл для объядинения всех функций.  
 * -------------------------------------------------------------
 */

void SetupDevice() {
  SetupHID();
  SetupRaw();
}

void LoopDevice() {
  LoopHID();
  LoopRaw();
}
