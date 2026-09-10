using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace MatlabHi {
    // Process-local, one-shot wait: no timeBeginPeriod or system settings.
    public sealed class HighResolutionWaiter : IDisposable {
        private IntPtr timer;
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        private static extern IntPtr CreateWaitableTimerExW(IntPtr attributes, string name, uint flags, uint access);
        [DllImport("kernel32.dll", SetLastError=true)]
        private static extern bool SetWaitableTimer(IntPtr timer, ref long due, int period, IntPtr callback, IntPtr arg, bool resume);
        [DllImport("kernel32.dll", SetLastError=true)]
        private static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);
        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr handle);
        public HighResolutionWaiter() {
            timer=CreateWaitableTimerExW(IntPtr.Zero,null,2,0x00100002);
            if(timer==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        }
        public void Wait() {
            if(timer==IntPtr.Zero) throw new ObjectDisposedException("HighResolutionWaiter");
            long due=-2500; // Relative 250 microseconds, in 100-ns units.
            if(!SetWaitableTimer(timer,ref due,0,IntPtr.Zero,IntPtr.Zero,false))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            if(WaitForSingleObject(timer,1000)!=0)
                throw new Win32Exception(Marshal.GetLastWin32Error());
        }
        public void Dispose() {
            if(timer!=IntPtr.Zero) { CloseHandle(timer); timer=IntPtr.Zero; }
            GC.SuppressFinalize(this);
        }
        ~HighResolutionWaiter() { Dispose(); }
    }
}
