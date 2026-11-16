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
    [Test] public void NormalReelingCanLandFish()
    {
        var s = new FishingSession();
        s.Cast();
        s.Hook();
        for (var i = 0; i < 6; i++) s.Tick(true, 1f);
        Assert.AreEqual(FishingState.Landed, s.State);
        Assert.AreEqual(1, s.Catches);
    }
    [Test] public void LandingAllowsAnotherCast()
    {
        var s = new FishingSession();
        s.Cast(); s.Hook();
        for (var i = 0; i < 6; i++) s.Tick(true, 1f);
        s.Cast();
        Assert.AreEqual(FishingState.Casting, s.State);
        Assert.AreEqual(1, s.Catches);
    }
    [Test] public void InactivityEventuallyEscapes()
    {
        var s = new FishingSession(); s.Cast(); s.Hook(); s.Tick(false, 31f);
        Assert.AreEqual(FishingState.Escaped, s.State);
    }
}
