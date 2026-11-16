using NUnit.Framework;
using GameStudio.Fishing;

public class FishingSessionTests
{
    [Test] public void CastAndHookChangeState()
    {
        var s = new FishingSession();
        s.Cast(); Assert.AreEqual(FishingState.Casting, s.State);
        Assert.IsTrue(s.Hook()); Assert.AreEqual(FishingState.Hooked, s.State);
    }
    [Test] public void ReelAccumulatesProgress()
    {
        var s = new FishingSession(); s.Cast(); s.Hook(); s.Tick(true, 1f);
        Assert.Greater(s.Progress, 0f);
    }
    [Test] public void InactivityEventuallyEscapes()
    {
        var s = new FishingSession(); s.Cast(); s.Hook(); s.Tick(false, 31f);
        Assert.AreEqual(FishingState.Escaped, s.State);
    }
}
