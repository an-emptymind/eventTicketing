const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Loyalty Ticketing System", function () {
  let LoyaltyToken, TicketNFT, TicketManager;
  let loyalty, nft, manager;
  let admin, user1, user2;

  beforeEach(async () => {
    [admin, user1, user2] = await ethers.getSigners();

    LoyaltyToken = await ethers.getContractFactory("RaghavLoyaltyToken");
    loyalty = await LoyaltyToken.deploy("Loyalty", "LTY", 18);
    await loyalty.waitForDeployment();
    loyaltyAddress = await loyalty.getAddress();
    

    TicketNFT = await ethers.getContractFactory("RaghavTicketNFT");
    nft = await TicketNFT.deploy("EventNFT", "ETKT");
    await nft.waitForDeployment();
    nftAddress = await nft.getAddress();

    TicketManager = await ethers.getContractFactory("RaghavTicketManager");
    manager = await TicketManager.deploy(loyaltyAddress, nftAddress);
    await manager.waitForDeployment();
    managerAddress = await manager.getAddress();

    // Grant minting rights to the manager
    await loyalty.connect(admin).updateTicketManager(managerAddress);
    await nft.connect(admin).updateTicketManager(managerAddress);
  });

  it("should create an event", async () => {
    const tx = await manager.connect(admin).createEvent(
      "Concert",
      Math.floor(Date.now() / 1000) + 3600,
      Math.floor(Date.now() / 1000) + 7200,
      100,
      10,
      50
    );
    await tx.wait();
    const event = await manager.eventId(1);
    expect(event.eventName).to.equal("Concert");
    expect(event.totalTickets).to.equal(50);
  });

  it("should allow a user to purchase tickets and receive rewards", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("Game", now + 1000, now + 5000, 200, 5, 20);
    
    // fast-forward time if needed or simulate purchase
    await manager.connect(user1).purchaseTicket(1, 2, 400);

    expect(await nft.balanceOf(user1.address)).to.equal(2);
    expect(await loyalty.balanceOf(user1.address)).to.equal(10);
  });

  it("should allow admin to update ticket price and reward", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("Seminar", now + 1000, now + 5000, 150, 8, 30);

    await manager.connect(admin).updatePrice(1, 180);
    await manager.connect(admin).updateReward(1, 12);

    const event = await manager.eventId(1);
    expect(event.ticketPrice).to.equal(180);
    expect(event.rewardAmount).to.equal(12);
  });

  it("should prevent unauthorized minting", async () => {
    await expect(loyalty.connect(user1).mint(user1.address, 100)).to.be.revertedWith("Unauthorized");
    await expect(nft.connect(user2).mint(user2.address, 1, "Event", 0, 0, "Seat")).to.be.revertedWith("Unauthorized");
  });

    it("should allow loyalty token transfers and approvals", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("TransferTest", now + 1000, now + 5000, 100, 20, 10);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    expect(await loyalty.balanceOf(user1.address)).to.equal(20);

    await loyalty.connect(user1).transfer(user2.address, 5);
    expect(await loyalty.balanceOf(user2.address)).to.equal(5);

    await loyalty.connect(user1).approve(user2.address, 10);
    await loyalty.connect(user2).transferFrom(user1.address, user2.address, 10);
    expect(await loyalty.balanceOf(user2.address)).to.equal(15);
  });

  it("should reject loyalty token transfers exceeding balance or allowance", async () => {
    await expect(loyalty.connect(user1).transfer(user2.address, 999))
      .to.be.revertedWith("Insufficient balance");

    await expect(loyalty.connect(user1).transferFrom(user2.address, user1.address, 1))
      .to.be.revertedWith("Insufficient balance");
  });

  it("should allow NFT approval and transferFrom by approved user", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("NFTTest", now + 1000, now + 5000, 100, 10, 5);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    const tokenId = 1;
    await nft.connect(user1).approve(user2.address, tokenId);
    await nft.connect(user2).transferFrom(user1.address, user2.address, tokenId);

    expect(await nft.ownerOf(tokenId)).to.equal(user2.address);
  });

  it("should not allow unauthorized NFT transfers", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("HackTest", now + 1000, now + 5000, 100, 10, 3);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    const tokenId = 1;

    await expect(
      nft.connect(user2).transferFrom(user1.address, user2.address, tokenId)
    ).to.be.revertedWith("Not authorized");
  });

  it("should store correct NFT metadata", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("MetaEvent", now + 1000, now + 5000, 100, 5, 10);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    const ticket = await nft.ticketInfo(1);
    expect(ticket.eventName).to.equal("MetaEvent");
    expect(ticket.seat).to.equal("Seat-1");
  });

    it("should set correct name, symbol, and admin in NFT contract", async () => {
    expect(await nft.name()).to.equal("EventNFT");
    expect(await nft.symbol()).to.equal("ETKT");
    expect(await nft.admin()).to.equal(admin.address);
  });


    it("should clear approval after transferFrom", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("ClearApproval", now + 1000, now + 5000, 100, 5, 1);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    await nft.connect(user1).approve(user2.address, 1);
    await nft.connect(user2).transferFrom(user1.address, user2.address, 1);

    const approved = await nft.approved(1);
    expect(approved).to.equal(ethers.ZeroAddress);
  });


  it("should revert if transferFrom is called by non-approved user", async () => {
    const now = Math.floor(Date.now() / 1000);
    await manager.connect(admin).createEvent("NonApprovedTransfer", now + 1000, now + 5000, 100, 5, 1);
    await manager.connect(user1).purchaseTicket(1, 1, 100);

    await expect(
      nft.connect(user2).transferFrom(user1.address, user2.address, 1)
    ).to.be.revertedWith("Not authorized");
  });





});

