 Ubuntu VM 설치 직후부터 전체 순서입니다.                                                                                                                                   
                                                                                                                                                                             
                                                                                                                                                                             
                                                                                                                                                                             
  # 1. 시스템 업데이트                                                                                                                                                       
                                                                                                                                                                             
  sudo apt update && sudo apt upgrade -y                                                                                                                                     
                                                                                                                                                                             
                                                                                                                                                                             
                                                                                                                                                                             
  # 2. Flutter 빌드에 필요한 패키지 설치                                                                                                                                     
  sudo apt install -y git clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev curl                                                                                    
                                                                                                                                                                             
  # 3. Flutter 설치                                                                                                                                                          
  sudo snap install flutter --classic                                                                                                                                        
                                                                                                                                                                             
  # 4. Flutter doctor로 환경 확인                                                                                                                                            
  flutter doctor                                                                                                                                                             
                                                                                                                                                                             
  # 5. 프로젝트 클론                                                                                                                                                         
  git clone https://github.com/kihyun1998/flutter_alone.git                                                                                                                  
  cd flutter_alone/example                                                                                                                                                   
                                                                                                                                                                             
  # 6. 패키지 받기                                                                                                                                                           
  flutter pub get                                                                                                                                                            
                                                                                                                                                                             
  # 7. 빌드 & 실행                                                                                                                                                           
  flutter run -d linux                                                                                                                                                       
                                                                                                                                                                             
  flutter doctor에서 빨간색 뜨는 항목 있으면 알려주세요. 이거 문서로 일단 쓰고 커밋만 하고 나중에 테스트 해봐야겠다.  