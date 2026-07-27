

const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const products = [
  {
    id: "product_0",
    name: "Wireless Earbuds",
    price: 1299.0,
    originalPrice: 2199.0,
    category: "Electronics",
    description: "True wireless stereo earbuds with 24hr battery life.",
    stock: 15,
    imageUrl: "",
  },
  {
    id: "product_1",
    name: "Smart Watch",
    price: 2499.0,
    originalPrice: 3999.0,
    category: "Electronics",
    description: "Fitness tracker with heart rate monitor and GPS.",
    stock: 10,
    imageUrl: "",
  },
  {
    id: "product_2",
    name: "Running Shoes",
    price: 1899.0,
    originalPrice: 2499.0,
    category: "Sports",
    description: "Lightweight running shoes with cushioned sole.",
    stock: 20,
    imageUrl: "",
  },
  {
    id: "product_3",
    name: "Cotton Kurta",
    price: 599.0,
    originalPrice: 999.0,
    category: "Fashion",
    description: "Premium cotton kurta with traditional embroidery.",
    stock: 30,
    imageUrl: "",
  },
  {
    id: "product_4",
    name: "Non-stick Cookware Set",
    price: 1499.0,
    originalPrice: 2299.0,
    category: "Home & Kitchen",
    description: "5-piece non-stick cookware set.",
    stock: 8,
    imageUrl: "",
  },
  {
    id: "product_5",
    name: "Vitamin C Serum",
    price: 449.0,
    originalPrice: 699.0,
    category: "Beauty",
    description: "Brightening vitamin C serum with hyaluronic acid.",
    stock: 25,
    imageUrl: "",
  },
  {
    id: "product_6",
    name: "Atomic Habits",
    price: 349.0,
    originalPrice: 499.0,
    category: "Books",
    description: "James Clear's #1 bestseller on building good habits.",
    stock: 50,
    imageUrl: "",
  },
  {
    id: "product_7",
    name: "Bluetooth Speaker",
    price: 999.0,
    originalPrice: 1599.0,
    category: "Electronics",
    description: "Portable waterproof speaker with 360 surround sound.",
    stock: 12,
    imageUrl: "",
  },
  {
    id: "product_8",
    name: "Yoga Mat",
    price: 699.0,
    originalPrice: 999.0,
    category: "Sports",
    description: "Anti-slip 6mm thick yoga mat with carry strap.",
    stock: 18,
    imageUrl: "",
  },
  {
    id: "product_9",
    name: "Face Moisturizer",
    price: 299.0,
    originalPrice: 450.0,
    category: "Beauty",
    description: "Lightweight daily moisturizer with SPF 30.",
    stock: 40,
    imageUrl: "",
  },
  {
    id: "product_10",
    name: "Denim Jacket",
    price: 1199.0,
    originalPrice: 1799.0,
    category: "Fashion",
    description: "Classic slim-fit denim jacket. Unisex design.",
    stock: 14,
    imageUrl: "",
  },
  {
    id: "product_11",
    name: "Air Fryer",
    price: 3299.0,
    originalPrice: 4999.0,
    category: "Home & Kitchen",
    description: "4.5L digital air fryer with 8 preset modes.",
    stock: 6,
    imageUrl: "",
  },
];

async function seedProducts() {
  const collectionRef = db.collection("products");

  // Check if already seeded
  const existing = await collectionRef.limit(1).get();
  if (!existing.empty) {
    console.log("  Products collection already has data. Skipping seed.");
    console.log("   Delete the collection in Firebase Console first if you want to re-seed.");
    process.exit(0);
  }

  console.log(` Seeding ${products.length} products to Firestore...\n`);

  // Use a batch write — all 12 in one network call
  const batch = db.batch();

  for (const product of products) {
    // Use the product id as the Firestore document id
    const docRef = collectionRef.doc(product.id);
    batch.set(docRef, product);
    console.log(`  ✓ Queued: ${product.name}`);
  }

  await batch.commit();

  console.log(`\n Done! ${products.length} products added to Firestore.`);
  console.log("   You can now view them in Firebase Console → Firestore → products");
  process.exit(0);
}

seedProducts().catch((err) => {
  console.error(" Seeding failed:", err.message);
  process.exit(1);
});