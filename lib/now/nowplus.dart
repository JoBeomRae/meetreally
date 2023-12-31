import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NowPlusPage extends StatefulWidget {
  const NowPlusPage({Key? key}) : super(key: key);

  @override
  _NowPlusPageState createState() => _NowPlusPageState();
}

class _NowPlusPageState extends State<NowPlusPage> {
  final TextEditingController _siController = TextEditingController();
  final TextEditingController _guController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();
  bool _enableSubmitButton = false;

  Map<String, Map<String, List<String>>> locations = {
    '대구광역시': {
      '중구': ['동인동', '삼덕동', '성내동', '대신동', '남산동', '대봉동'],
      '동구': [
        '신암동',
        '신천동',
        '효목동',
        '도평동',
        '불로·동무동',
        '지저동',
        '동촌동',
        '방촌동',
        '해안동',
        '공산동',
        '안심동',
        '혁신동'
      ],
      '서구': ['비산동', '내당동', '평리동', '상중이동', '원대동'],
      '남구': ['이천동', '봉덕동', '대명동'],
      '북구': ['고성동', '칠성동', '침산동', '노원동', '산격동', '복현동', '대현동', '검단동'],
      '수성구': ['범어동', '만촌동', '수성가동', '황금동', '중동', '상동', '두산동', '지산동', '범물동'],
      '달서구': [
        '성당동',
        '두류동',
        '감상동',
        '죽전동',
        '장기동',
        '용산동',
        '이곡동',
        '신당동',
        '본리동',
        '본동',
        '월성동',
        '진천동',
        '유천동',
        '상인동',
        '도원동',
        '송현동'
      ],
      '달성군': ['동'],
      '군위군': ['동'],
    },
  };

  String? selectedSi;
  List<String>? selectedGuList;
  String? selectedGu;
  String? selectedPeople;
  int? selectedPeopleCount;
  String? selectedDong;
  List<String>? selectedDongList;

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _checkInputValid() {
    setState(() {
      int selectedFriendsCount =
          _controllers.where((controller) => controller.text.isNotEmpty).length;
      _enableSubmitButton = (selectedSi != null &&
          selectedGu != null &&
          selectedPeopleCount != null &&
          selectedPeopleCount == selectedFriendsCount);
    });
  }

  @override
  void initState() {
    super.initState();
    _siController.addListener(_checkInputValid);
    _guController.addListener(_checkInputValid);
    _personController.addListener(_checkInputValid);
  }

  void _showFriendPicker(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final userNickname = userData['nickname'];
                  final userAge = userData['age'];
                  final userJob = userData['job'];

                  return ListTile(
                    title: Text('$userNickname ($userAge, $userJob)'),
                    onTap: () {
                      _selectFriend(
                          index, '$userNickname ($userAge, $userJob)');
                    },
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('friends')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friends = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, position) {
                        final friendData =
                            friends[position].data() as Map<String, dynamic>;

                        final nickname = friendData['nickname'];
                        final age = friendData['age'];
                        final job = friendData['job'];

                        return ListTile(
                          title: Text('$nickname ($age, $job)'),
                          onTap: () {
                            _selectFriend(index, '$nickname ($age, $job)');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectFriend(int index, String friendName) {
    if (!_controllers.any((controller) => controller.text == friendName)) {
      setState(() {
        _controllers[index].text = friendName;
        _checkInputValid(); // 추가된 부분
      });
      Navigator.pop(context);
    } else {
      _showAlert(context, '이미 선택된 친구입니다. 다른 친구를 선택해주세요.');
    }
  }

  @override
  void dispose() {
    _siController.dispose();
    _guController.dispose();
    _personController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 24.0), // 이 부분을 추가합니다.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(children: [
              // 뒤로 가기 버튼 추가
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // 시
              Center(
                child: DropdownButton<String>(
                  value: selectedSi,
                  items: locations.keys.map((String si) {
                    return DropdownMenuItem<String>(
                      value: si,
                      child: Text(si),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSi = newValue;
                      _siController.text = newValue!;
                      selectedGuList = locations[newValue]?.keys.toList();
                      selectedGu = null;
                      _guController.text = '';
                    });
                  },
                  hint: const Text('시를 선택해주세요.(필수)'),
                ),
              ),
              const SizedBox(height: 16),
              // 구
              Center(
                child: DropdownButton<String>(
                  value: selectedGu,
                  items: selectedGuList?.map((String gu) {
                    return DropdownMenuItem<String>(
                      value: gu,
                      child: Text(gu),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGu = newValue;
                      _guController.text = newValue!;
                      selectedDongList = locations[selectedSi]?[newValue];
                      selectedDong = null; // 동 선택 초기화
                    });
                  },
                  hint: const Text('구를 선택해주세요.(필수)'),
                ),
              ),
              const SizedBox(height: 16),
// 동
              Center(
                child: DropdownButton<String>(
                  value: selectedDong,
                  items: selectedDongList?.map((String dong) {
                    return DropdownMenuItem<String>(
                      value: dong,
                      child: Text(dong),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDong = newValue;
                    });
                  },
                  hint: const Text('동을 선택해주세요.(선택)'),
                ),
              ),
              const SizedBox(height: 16),
              // 인원
              Center(
                child: DropdownButton<int>(
                  value: selectedPeopleCount,
                  items: [1, 2, 3].map((int person) {
                    return DropdownMenuItem<int>(
                      value: person,
                      child: Text('$person명'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedPeopleCount = newValue;
                      _personController.text = '$newValue명';
                    });
                  },
                  hint: const Text('함께할 친구 수를 선택해주세요.(필수)'),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: selectedPeopleCount != null
                    ? List.generate(selectedPeopleCount!, (int index) {
                        while (_controllers.length <= index) {
                          _controllers.add(TextEditingController());
                        }
                        return Column(
                          children: [
                            // 변경 후
                            Container(
                              height: 50, // 원하는 높이로 조절하세요.
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  _showFriendPicker(index);
                                },
                                child: AbsorbPointer(
                                  child: _controllers[index]
                                          .text
                                          .isEmpty // 해당 인덱스의 컨트롤러의 텍스트가 비어있다면 힌트 텍스트를 표시
                                      ? const Center(child: Text("친구를 선택해주세요."))
                                      : TextField(
                                          controller: _controllers[index],
                                          decoration: InputDecoration(
                                            border: InputBorder
                                                .none, // 기존의 border를 제거
                                            labelText: '${index + 1}번째 친구',
                                            hintText: '닉네임을 입력해주세요.',
                                          ),
                                          textAlign: TextAlign
                                              .center, // 텍스트 정렬을 중앙으로 설정
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      })
                    : [],
              ),
              // 등록하기 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _enableSubmitButton
                    ? () {
                        var dataToReturn = {
                          'si': selectedSi,
                          'gu': selectedGu,
                          'dong': selectedDong,
                          'friends': _controllers.map((e) => e.text).toList(),
                        };

                        Navigator.pop(context, dataToReturn);
                      }
                    : null, // 버튼 비활성화
                child: const Text('등록하기'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
