// Game version: "1.1.2", Godot version: "4.6.2", Process: "erdetspill", Platform: "Windows".

state("erdetspill") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");

    vars.scriptVersion = "1.1.2";
    version = vars.scriptVersion + " (Uhara10)";

    refreshRate = 120;
    vars.Uhara.AlertGameTime();

    dynamic[,] _settings =
    {
        { "quest_unlocks", true, "Quest Unlocks", null },
        { "UnlockInheritanceDocument", true, "Redeem the Inheritance Document - ARVEDOKUMENTET", "quest_unlocks" },
        { "UnlockBuyIceCream", true, "Buy Ice Cream - KJØP IS", "quest_unlocks" },
        { "UnlockReturnToGrandpa", true, "Return to Grandpa - TILBAKE TIL BESTEFAR", "quest_unlocks" },
        { "UnlockScholarship", true, "Apply for a Scholarship - STIPEND", "quest_unlocks" },
        { "UnlockReturnToBank", true, "Return to the Bank - TILBAKE TIL BANKEN", "quest_unlocks" },
        { "UnlockLastIceCream", true, "Buy the Last Ice Cream - EN IS TIL", "quest_unlocks" },
        { "UnlockSlaughter", true, "Slaughter in the Name of Gravel - SLAKT I GRUSENS NAVN", "quest_unlocks" },
        { "UnlockKristofferCap", true, "Return Kristoffer's Cap - CAPSEN TIL KRISTOFFER", "quest_unlocks" },
        { "UnlockNoPower", true, "Restore the Power - INGEN STRØM", "quest_unlocks" },
        { "UnlockDeliverIceCream", true, "Deliver the Ice Cream - LEVER ISEN", "quest_unlocks" },
        { "End", true, "Finish the Game - LEVER ISEN (END)", null },
    };
    vars.Uhara.Settings.Create(_settings);

    vars.timerMembers = IntPtr.Zero;
    vars.gameManagerMembers = IntPtr.Zero;
    vars.timerReady = false;
    vars.scanCooldown = 0;
    vars.gameManagerScanCooldown = 0;
    vars.previousActiveQuestMask = -1;
    vars.restartArmed = false;
    vars.questSplitQueue = new Queue<int>();
    vars.questSettingKeys = new string[]
    {
        "UnlockInheritanceDocument",
        "UnlockBuyIceCream",
        "UnlockReturnToGrandpa",
        "UnlockScholarship",
        "UnlockReturnToBank",
        "UnlockLastIceCream",
        "UnlockSlaughter",
        "UnlockKristofferCap",
        "UnlockNoPower",
        "UnlockDeliverIceCream"
    };

    // This helper is compiled in memory by LiveSplit.
    string readerSource = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public static class ErdetspillGodotReader
{
    [StructLayout(LayoutKind.Sequential)]
    private struct MemoryBasicInformation
    {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public ushort PartitionId;
        public UIntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }

    [DllImport(""kernel32.dll"", SetLastError = true)]
    private static extern int VirtualQueryEx(
        IntPtr process, IntPtr address, out MemoryBasicInformation info, UIntPtr length);

    [DllImport(""kernel32.dll"", SetLastError = true)]
    private static extern bool ReadProcessMemory(
        IntPtr process, IntPtr address, byte[] buffer, UIntPtr size, out UIntPtr bytesRead);

    private static bool IsTimerMembers(byte[] data, int i)
    {
        // Three consecutive 24-byte Godot Variants:
        // BOOL _running, FLOAT _elapsed, OBJECT _timer_label.
        if (BitConverter.ToInt32(data, i) != 1 || data[i + 8] > 1)
            return false;
        for (int j = 9; j < 24; j++)
            if (data[i + j] != 0) return false;

        if (BitConverter.ToInt32(data, i + 24) != 3)
            return false;
        for (int j = 28; j < 32; j++)
            if (data[i + j] != 0) return false;
        double elapsed = BitConverter.ToDouble(data, i + 32);
        if (Double.IsNaN(elapsed) || Double.IsInfinity(elapsed) ||
            elapsed < 0.0 || elapsed >= 864000.0)
            return false;
        for (int j = 40; j < 48; j++)
            if (data[i + j] != 0) return false;

        if (BitConverter.ToInt32(data, i + 48) != 24)
            return false;
        for (int j = 52; j < 56; j++)
            if (data[i + j] != 0) return false;
        ulong objectId = BitConverter.ToUInt64(data, i + 56);
        ulong objectPointer = BitConverter.ToUInt64(data, i + 64);
        return objectId != 0 && (objectId & 0x8000000000000000UL) == 0 &&
            objectPointer >= 0x10000UL && objectPointer < 0x0000800000000000UL;
    }

    private static bool IsGameManagerMembers(byte[] data, int i)
    {
        // The first twelve GameManager members have a stable and distinctive
        // Variant type sequence. Their values may change during a run.
        int[] types = { 2, 3, 4, 2, 2, 27, 27, 27, 28, 27, 2, 27 };
        for (int member = 0; member < types.Length; member++)
        {
            int variant = i + member * 24;
            if (BitConverter.ToInt32(data, variant) != types[member])
                return false;
            for (int j = 4; j < 8; j++)
                if (data[variant + j] != 0) return false;
        }

        double dayDuration = BitConverter.ToDouble(data, i + 32);
        return dayDuration > 0.0 && dayDuration < 86400.0;
    }

    private static byte[] ReadBytes(Process game, long address, int size)
    {
        if (address < 0x10000 || size <= 0)
            return null;
        byte[] data = new byte[size];
        UIntPtr bytesRead;
        if (!ReadProcessMemory(game.Handle, new IntPtr(address), data,
            new UIntPtr((uint)size), out bytesRead) || bytesRead.ToUInt64() < (ulong)size)
            return null;
        return data;
    }

    private static string ReadGodotString(Process game, long address)
    {
        byte[] data = ReadBytes(game, address, 128);
        if (data == null)
            return """";
        int byteLength = 0;
        while (byteLength + 3 < data.Length &&
            BitConverter.ToUInt32(data, byteLength) != 0)
            byteLength += 4;
        return Encoding.UTF32.GetString(data, 0, byteLength);
    }

    private static int QuestBit(string questId)
    {
        switch (questId)
        {
            case ""BANK_INHERITANCE"": return 1 << 0;
            case ""ECONOMIC_REALITY"": return 1 << 1;
            case ""GRANDPA_DISAPPOINTMENT"": return 1 << 2;
            case ""SCHOLARSHIP_APPLICATION"": return 1 << 3;
            case ""BANK_DEPOSIT"": return 1 << 4;
            case ""SECOND_ICECREAM"": return 1 << 5;
            case ""IVER_BEVIS"": return 1 << 6;
            case ""KRIS_LUA"": return 1 << 7;
            case ""HVERDAGSKOMIKER"": return 1 << 8;
            case ""FINAL_DELIVERY"": return 1 << 9;
            default: return 0;
        }
    }

    public static int GetActiveQuestMask(Process game, IntPtr gameManagerMembers)
    {
        if (gameManagerMembers == IntPtr.Zero)
            return 0;

        // gameManagerMembers points at current_day. active_quests is member 6.
        byte[] dictionaryVariant = ReadBytes(game,
            gameManagerMembers.ToInt64() + 6 * 24, 24);
        if (dictionaryVariant == null || BitConverter.ToInt32(dictionaryVariant, 0) != 27)
            return 0;

        long dictionary = BitConverter.ToInt64(dictionaryVariant, 8);
        byte[] dictionaryHeader = ReadBytes(game, dictionary, 64);
        if (dictionaryHeader == null)
            return 0;

        // DictionaryPrivate contains its HashMap at +0x10. The linked-list
        // head and size are therefore at +0x20 and +0x34 respectively.
        long element = BitConverter.ToInt64(dictionaryHeader, 0x20);
        uint count = BitConverter.ToUInt32(dictionaryHeader, 0x34);
        if (count > 128)
            return 0;

        int mask = 0;
        for (uint i = 0; i < count && element >= 0x10000; i++)
        {
            // HashMapElement: next, previous, key Variant, value Variant.
            byte[] entry = ReadBytes(game, element, 64);
            if (entry == null)
                break;
            if (BitConverter.ToInt32(entry, 16) == 4)
            {
                long stringData = BitConverter.ToInt64(entry, 24);
                mask |= QuestBit(ReadGodotString(game, stringData));
            }
            element = BitConverter.ToInt64(entry, 0);
        }
        return mask;
    }

    public static IntPtr FindTimer(Process game)
    {
        const uint MemCommit = 0x1000;
        const uint PageGuard = 0x100;
        const uint PageNoAccess = 0x01;
        const int RecordSize = 72;
        const int ChunkSize = 4 * 1024 * 1024;

        ulong address = 0;
        ulong maximum = Environment.Is64BitProcess
            ? 0x00007FFFFFFFFFFFUL : 0x7FFFFFFFUL;

        while (address < maximum)
        {
            MemoryBasicInformation info;
            int queried = VirtualQueryEx(game.Handle, new IntPtr((long)address),
                out info, new UIntPtr((uint)Marshal.SizeOf(typeof(MemoryBasicInformation))));
            if (queried == 0)
                break;

            ulong regionBase = (ulong)info.BaseAddress.ToInt64();
            ulong regionSize = info.RegionSize.ToUInt64();
            uint basicProtection = info.Protect & 0xFF;
            bool writable = basicProtection == 0x04 || basicProtection == 0x08 ||
                basicProtection == 0x40 || basicProtection == 0x80;

            if (info.State == MemCommit && writable &&
                (info.Protect & PageGuard) == 0 &&
                (info.Protect & PageNoAccess) == 0 && regionSize >= RecordSize)
            {
                ulong offset = 0;
                while (offset < regionSize)
                {
                    ulong remaining = regionSize - offset;
                    int wanted = (int)Math.Min((ulong)ChunkSize, remaining);
                    byte[] data = new byte[wanted];
                    UIntPtr bytesRead;
                    if (ReadProcessMemory(game.Handle,
                        new IntPtr((long)(regionBase + offset)), data,
                        new UIntPtr((uint)wanted), out bytesRead))
                    {
                        int count = (int)Math.Min((ulong)wanted, bytesRead.ToUInt64());
                        for (int i = 0; i <= count - RecordSize; i += 8)
                            if (IsTimerMembers(data, i))
                                return new IntPtr((long)(regionBase + offset + (ulong)i));
                    }

                    if (remaining <= (ulong)ChunkSize)
                        break;
                    offset += (ulong)(ChunkSize - RecordSize);
                }
            }

            if (regionSize == 0 || regionBase > UInt64.MaxValue - regionSize)
                break;
            address = regionBase + regionSize;
        }

        return IntPtr.Zero;
    }

    public static IntPtr FindGameManager(Process game)
    {
        const uint MemCommit = 0x1000;
        const uint PageGuard = 0x100;
        const uint PageNoAccess = 0x01;
        const int RecordSize = 12 * 24;
        const int ChunkSize = 4 * 1024 * 1024;

        ulong address = 0;
        ulong maximum = Environment.Is64BitProcess
            ? 0x00007FFFFFFFFFFFUL : 0x7FFFFFFFUL;

        while (address < maximum)
        {
            MemoryBasicInformation info;
            int queried = VirtualQueryEx(game.Handle, new IntPtr((long)address),
                out info, new UIntPtr((uint)Marshal.SizeOf(typeof(MemoryBasicInformation))));
            if (queried == 0)
                break;

            ulong regionBase = (ulong)info.BaseAddress.ToInt64();
            ulong regionSize = info.RegionSize.ToUInt64();
            uint basicProtection = info.Protect & 0xFF;
            bool writable = basicProtection == 0x04 || basicProtection == 0x08 ||
                basicProtection == 0x40 || basicProtection == 0x80;

            if (info.State == MemCommit && writable &&
                (info.Protect & PageGuard) == 0 &&
                (info.Protect & PageNoAccess) == 0 && regionSize >= RecordSize)
            {
                ulong offset = 0;
                while (offset < regionSize)
                {
                    ulong remaining = regionSize - offset;
                    int wanted = (int)Math.Min((ulong)ChunkSize, remaining);
                    byte[] data = new byte[wanted];
                    UIntPtr bytesRead;
                    if (ReadProcessMemory(game.Handle,
                        new IntPtr((long)(regionBase + offset)), data,
                        new UIntPtr((uint)wanted), out bytesRead))
                    {
                        int count = (int)Math.Min((ulong)wanted, bytesRead.ToUInt64());
                        for (int i = 0; i <= count - RecordSize; i += 8)
                            if (IsGameManagerMembers(data, i))
                                return new IntPtr((long)(regionBase + offset + (ulong)i));
                    }

                    if (remaining <= (ulong)ChunkSize)
                        break;
                    offset += (ulong)(ChunkSize - RecordSize);
                }
            }

            if (regionSize == 0 || regionBase > UInt64.MaxValue - regionSize)
                break;
            address = regionBase + regionSize;
        }

        return IntPtr.Zero;
    }
}
";

    var provider = new Microsoft.CSharp.CSharpCodeProvider();
    var parameters = new System.CodeDom.Compiler.CompilerParameters();
    parameters.GenerateExecutable = false;
    parameters.GenerateInMemory = true;
    parameters.ReferencedAssemblies.Add("System.dll");
    var compiled = provider.CompileAssemblyFromSource(parameters, readerSource);

    if (compiled.Errors.HasErrors)
    {
        foreach (System.CodeDom.Compiler.CompilerError error in compiled.Errors)
            print("Erdetspill Godot reader: " + error.ToString());
        vars.findTimer = null;
        vars.findGameManager = null;
        vars.getActiveQuestMask = null;
    }
    else
    {
        var method = compiled.CompiledAssembly
            .GetType("ErdetspillGodotReader").GetMethod("FindTimer");
        vars.findTimer = (Func<System.Diagnostics.Process, IntPtr>)Delegate.CreateDelegate(
            typeof(Func<System.Diagnostics.Process, IntPtr>), method);
        var gameManagerMethod = compiled.CompiledAssembly
            .GetType("ErdetspillGodotReader").GetMethod("FindGameManager");
        vars.findGameManager = (Func<System.Diagnostics.Process, IntPtr>)Delegate.CreateDelegate(
            typeof(Func<System.Diagnostics.Process, IntPtr>), gameManagerMethod);
        var activeQuestMethod = compiled.CompiledAssembly
            .GetType("ErdetspillGodotReader").GetMethod("GetActiveQuestMask");
        vars.getActiveQuestMask = (Func<System.Diagnostics.Process, IntPtr, int>)Delegate.CreateDelegate(
            typeof(Func<System.Diagnostics.Process, IntPtr, int>), activeQuestMethod);
    }
}

init
{
    vars.timerMembers = IntPtr.Zero;
    vars.gameManagerMembers = IntPtr.Zero;
    vars.timerReady = false;
    vars.scanCooldown = 0;
    vars.gameManagerScanCooldown = 0;
    vars.previousActiveQuestMask = -1;
    vars.restartArmed = false;
    vars.questSplitQueue.Clear();

    vars.Uhara.Log("Erdetspill Autosplitter v" + vars.scriptVersion +
        " (Uhara10) attached to Erdetspill " + vars.Uhara.GetMD5Hash());
}

update
{
    if (vars.timerMembers == IntPtr.Zero && vars.findTimer != null)
    {
        if (vars.scanCooldown <= 0)
        {
            vars.scanCooldown = refreshRate;
            vars.timerMembers = vars.findTimer(game);

            if (vars.timerMembers != IntPtr.Zero)
            {
                vars.Resolver.Watch<bool>("timerRunning", IntPtr.Add(vars.timerMembers, 0x08));
                vars.Resolver.Watch<double>("igt", IntPtr.Add(vars.timerMembers, 0x20));
                vars.Uhara.Log("SpeedrunTimer members found at 0x" +
                    vars.timerMembers.ToInt64().ToString("X"));
            }
        }
        else
        {
            vars.scanCooldown--;
        }
    }

    if (vars.gameManagerMembers == IntPtr.Zero && vars.findGameManager != null)
    {
        if (vars.gameManagerScanCooldown <= 0)
        {
            vars.gameManagerScanCooldown = refreshRate;
            vars.gameManagerMembers = vars.findGameManager(game);
            if (vars.gameManagerMembers != IntPtr.Zero)
            {
                // GameManager member 56 is _ending_sequence_started. Each Godot Variant is 24 bytes and its bool payload begins eight bytes in.
                vars.Resolver.Watch<bool>("endingStarted",
                    IntPtr.Add(vars.gameManagerMembers, 0x548));
                vars.Uhara.Log("GameManager members found at 0x" +
                    vars.gameManagerMembers.ToInt64().ToString("X"));
            }
        }
        else
            vars.gameManagerScanCooldown--;
    }

    vars.Uhara.Update();

    if (vars.gameManagerMembers != IntPtr.Zero && vars.getActiveQuestMask != null)
    {
        int activeQuestMask = vars.getActiveQuestMask(game, vars.gameManagerMembers);
        if (vars.previousActiveQuestMask >= 0)
        {
            int newlyUnlocked = activeQuestMask & ~vars.previousActiveQuestMask;
            for (int bit = 0; bit < vars.questSettingKeys.Length; bit++)
                if ((newlyUnlocked & (1 << bit)) != 0 && settings[vars.questSettingKeys[bit]])
                    vars.questSplitQueue.Enqueue(bit);
        }
        vars.previousActiveQuestMask = activeQuestMask;
    }

    vars.timerReady = vars.timerMembers != IntPtr.Zero &&
        !Double.IsNaN((double)current.igt) &&
        !Double.IsInfinity((double)current.igt) &&
        (double)current.igt >= 0.0 &&
        (double)current.igt < 864000.0;

    return true;
}

start
{
        current.timerRunning &&
        (!old.timerRunning || vars.restartArmed) &&
        (double)current.igt < 1.0;
    if (shouldStart)
    {
        vars.restartArmed = false;
        vars.questSplitQueue.Clear();
        if (vars.gameManagerMembers != IntPtr.Zero && vars.getActiveQuestMask != null)
            vars.previousActiveQuestMask = vars.getActiveQuestMask(game, vars.gameManagerMembers);
    }
    return shouldStart;
}

split
{
    if (settings["End"] && vars.timerReady &&
        vars.gameManagerMembers != IntPtr.Zero &&
        !old.endingStarted && current.endingStarted)
        return true;

    if (vars.questSplitQueue.Count > 0)
    {
        vars.questSplitQueue.Dequeue();
        return true;
    }
    return false;
}

reset
{
    bool shouldReset = vars.timerReady &&
        (double)current.igt < 1.0 &&
        (double)old.igt > (double)current.igt + 0.05;
    if (shouldReset)
    {
        vars.restartArmed = true;
        vars.questSplitQueue.Clear();
        vars.previousActiveQuestMask = -1;
    }
    return shouldReset;
}

gameTime
{
    if (!vars.timerReady)
        return null;

    // The in-game label truncates (rather than rounds) to centiseconds.
    double centiseconds = Math.Floor((double)current.igt * 100.0);
    return TimeSpan.FromMilliseconds(centiseconds * 10.0);
}

isLoading
{
    return vars.timerReady;
}
