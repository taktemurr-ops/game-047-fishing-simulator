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
    [Test] public void CatchPaysCoinsAndUpgradeCostsCoins()
    {
        var s = new FishingSession();
        for (var fish = 0; fish < 2; fish++)
        {
            s.Cast();
            Assert.IsTrue(s.Hook());
            for (var i = 0; i < 6; i++) s.Tick(true, 1f);
            Assert.AreEqual(FishingState.Landed, s.State);
        }
        Assert.AreEqual(50, s.Coins);
        Assert.IsTrue(s.UpgradeReel());
        Assert.AreEqual(2, s.ReelLevel);
        Assert.AreEqual(0, s.Coins);
        Assert.IsFalse(s.UpgradeReel());
    }

    [Test] public void ReelUpgradeIncreasesProgressPerSecond()
    {
        var basic = new FishingSession();
        basic.Cast(); basic.Hook(); basic.Tick(true, 1f);
        var upgraded = new FishingSession();
        for (var fish = 0; fish < 2; fish++)
        {
            upgraded.Cast(); upgraded.Hook();
            for (var i = 0; i < 6; i++) upgraded.Tick(true, 1f);
        }
        Assert.IsTrue(upgraded.UpgradeReel());
        upgraded.Cast(); upgraded.Hook(); upgraded.Tick(true, 1f);
        Assert.Greater(upgraded.Progress, basic.Progress);
    }
    [Test] public void InvalidTimeIsRejectedEvenBeforeHooking()
    {
        var s = new FishingSession();
        Assert.Throws<System.ArgumentOutOfRangeException>(() => s.Tick(false, float.NaN));
        Assert.AreEqual(FishingState.Ready, s.State);
    }
}
