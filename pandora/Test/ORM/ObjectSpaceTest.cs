using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Google.Protobuf;
using NUnit.Framework;

using Pandora.ORM;

namespace Pandora.ORMTest
{
    class ObjectSpaceTest
    {
        ObjectSpaceDesc desc;

        Pandora.ORM.ObjectSpace space;
        Stream s;
        CodedOutputStream cs;

        static Dictionary<uint, Type> classIdDesc = new Dictionary<uint, Type>() { { 1, typeof(Pandora.ORMTest.Character) } };

        [SetUp]
        public void SetUp()
        {
            desc = new ObjectSpaceDesc() { ClassIdDict = classIdDesc };
            s = new MemoryStream();
            cs = new CodedOutputStream(s, true);
            space = new Pandora.ORM.ObjectSpace(desc);
            space.LogEnabled = true;
        }


        [Test]
        public void TestCreate()
        {
            var c1 = new Character() { Name = "Tanjiro" };
            var c2 = new Character() { Name = "Nezuko" };
            space.Register(c1, true);
            space.Register(c2, true);
            space.LogEnabled = true;

            space.WriteTo(cs);

            dump(s);

            var space2 = readSpace(s);

            Assert.AreEqual("Tanjiro", space2.GetEntity<Character>(1).Name);
            Assert.AreEqual("Nezuko", space2.GetEntity<Character>(2).Name);
        }

        [Test]
        public void TestUpdate()
        {
            var c1 = new Character() { Name = "Tanjiro" };
            space.Register(c1, true);
            space.LogEnabled = true;

            space.WriteTo(cs);

            c1.Name = "Tanjiro 2";
            space.WriteTo(cs);

            dump(s);

            var space2 = readSpace(s);

            Assert.AreEqual("Tanjiro 2", space2.GetEntity<Character>(1).Name);
        }

        Pandora.ORM.ObjectSpace readSpace(Stream s)
        {
            s.Seek(0, SeekOrigin.Begin);

            var space = new Pandora.ORM.ObjectSpace(desc);
            space.LogEnabled = true;
            space.ReadFrom(new CodedInputStream(s, false));
            return space;
        }

        void dump(Stream s)
        {
            Console.WriteLine(s.Length);
            var buf = new byte[16];
            s.Seek(0, SeekOrigin.Begin);
            while( true ){
                var len = s.Read(buf, 0, buf.Length);
                if (len <= 0) break;
                Console.WriteLine(BitConverter.ToString(buf, 0, len));
            }
        }

    }
}